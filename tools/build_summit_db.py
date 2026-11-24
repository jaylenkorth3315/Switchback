#!/usr/bin/env python3
"""Build the bundled summit database from USGS GNIS Domestic Names data.

Downloads GNIS state (or national) text files, filters to Summit-class
features, enriches elevations from the Copernicus GLO-90 DEM via the
Open-Meteo elevation API (GNIS dropped its elevation column in the 2021
redesign), and writes Switchback/Resources/summits.sqlite.

Note: a 90 m DEM slightly underreads sharp peaks; good enough for display
and stats. A future refinement is joining true summit elevations and
prominence from the Kirmse dataset.

Usage:
    python3 tools/build_summit_db.py --national
    python3 tools/build_summit_db.py --states CO WA CA
    python3 tools/build_summit_db.py --national --skip-elevation
"""
import argparse
import csv
import io
import json
import sqlite3
import sys
import time
import urllib.request
import zipfile
from pathlib import Path

BASE_URL = "https://prd-tnm.s3.amazonaws.com/StagedProducts/GeographicNames/DomesticNames/"
OUTPUT = Path(__file__).resolve().parent.parent / "Switchback" / "Resources" / "summits.sqlite"

# Header names vary across GNIS vintages; match case-insensitively.
NAME_KEYS = ("feature_name",)
CLASS_KEYS = ("feature_class",)
LAT_KEYS = ("prim_lat_dec", "primary_lat_dec")
LON_KEYS = ("prim_long_dec", "primary_long_dec")
ELEV_KEYS = ("elev_in_m",)
STATE_KEYS = ("state_name", "state_alpha")
COUNTY_KEYS = ("county_name",)


def fetch_zip(name: str) -> bytes:
    url = f"{BASE_URL}{name}"
    print(f"Downloading {url} ...", flush=True)
    with urllib.request.urlopen(url, timeout=300) as response:
        return response.read()


def pick(row: dict, keys: tuple) -> str:
    for key in keys:
        if key in row and row[key]:
            return row[key].strip()
    return ""


def parse_summits(zip_bytes: bytes):
    archive = zipfile.ZipFile(io.BytesIO(zip_bytes))
    txt_members = [m for m in archive.namelist() if m.lower().endswith(".txt")]
    if not txt_members:
        raise RuntimeError("No .txt member found in GNIS archive")
    summits = []
    for member in txt_members:
        with archive.open(member) as raw:
            text = io.TextIOWrapper(raw, encoding="utf-8", errors="replace")
            reader = csv.reader(text, delimiter="|")
            header = [h.strip().lower() for h in next(reader)]
            for values in reader:
                row = dict(zip(header, values))
                if pick(row, CLASS_KEYS).lower() != "summit":
                    continue
                name = pick(row, NAME_KEYS)
                lat_text = pick(row, LAT_KEYS)
                lon_text = pick(row, LON_KEYS)
                if not name or not lat_text or not lon_text:
                    continue
                try:
                    lat, lon = float(lat_text), float(lon_text)
                except ValueError:
                    continue
                if lat == 0 and lon == 0:
                    continue
                elev_text = pick(row, ELEV_KEYS)
                try:
                    elev = float(elev_text) if elev_text else None
                except ValueError:
                    elev = None
                summits.append((
                    name, elev, lat, lon,
                    pick(row, STATE_KEYS), pick(row, COUNTY_KEYS),
                ))
    return summits


def enrich_elevations(summits):
    """Fill in elevation (index 1) for every summit, 100 points per request."""
    enriched = []
    batch_size = 100
    total_batches = (len(summits) + batch_size - 1) // batch_size
    for batch_index in range(total_batches):
        batch = summits[batch_index * batch_size:(batch_index + 1) * batch_size]
        lats = ",".join(f"{s[2]:.5f}" for s in batch)
        lons = ",".join(f"{s[3]:.5f}" for s in batch)
        url = f"https://api.open-meteo.com/v1/elevation?latitude={lats}&longitude={lons}"
        elevations = [None] * len(batch)
        for attempt in range(6):
            try:
                with urllib.request.urlopen(url, timeout=60) as response:
                    payload = json.load(response)
                elevations = payload.get("elevation", elevations)
                break
            except urllib.error.HTTPError as error:
                if error.code == 429:
                    # Rate limited: wait out the window rather than burning retries.
                    time.sleep(30 * (attempt + 1))
                else:
                    print(f"  batch {batch_index + 1}/{total_batches} attempt {attempt + 1} failed: {error}", flush=True)
                    time.sleep(5)
            except Exception as error:
                print(f"  batch {batch_index + 1}/{total_batches} attempt {attempt + 1} failed: {error}", flush=True)
                time.sleep(5)
        for summit, elevation in zip(batch, elevations):
            enriched.append((summit[0], elevation, summit[2], summit[3], summit[4], summit[5]))
        if (batch_index + 1) % 50 == 0 or batch_index + 1 == total_batches:
            print(f"  elevations: {batch_index + 1}/{total_batches} batches", flush=True)
        time.sleep(1.2)
    return enriched


def build_database(summits):
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.unlink(missing_ok=True)
    connection = sqlite3.connect(OUTPUT)
    connection.executescript(
        """
        CREATE TABLE summits (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            elevation_m REAL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            state TEXT NOT NULL DEFAULT '',
            county TEXT NOT NULL DEFAULT ''
        );
        """
    )
    connection.executemany(
        "INSERT INTO summits (name, elevation_m, lat, lon, state, county) VALUES (?, ?, ?, ?, ?, ?)",
        summits,
    )
    connection.execute("CREATE INDEX idx_summits_lat_lon ON summits(lat, lon)")
    connection.commit()
    connection.execute("VACUUM")
    connection.close()
    size_mb = OUTPUT.stat().st_size / 1_048_576
    print(f"Wrote {len(summits)} summits to {OUTPUT} ({size_mb:.1f} MB)")


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--national", action="store_true")
    group.add_argument("--states", nargs="+", metavar="XX")
    parser.add_argument("--skip-elevation", action="store_true")
    args = parser.parse_args()

    all_summits = []
    if args.national:
        all_summits = parse_summits(fetch_zip("DomesticNames_National_Text.zip"))
    else:
        for state in args.states:
            data = fetch_zip(f"DomesticNames_{state.upper()}_Text.zip")
            found = parse_summits(data)
            print(f"  {state.upper()}: {len(found)} summits")
            all_summits.extend(found)

    if not all_summits:
        print("No summits parsed — aborting", file=sys.stderr)
        sys.exit(1)
    if not args.skip_elevation:
        print(f"Enriching elevations for {len(all_summits)} summits ...", flush=True)
        all_summits = enrich_elevations(all_summits)
    build_database(all_summits)


if __name__ == "__main__":
    main()
