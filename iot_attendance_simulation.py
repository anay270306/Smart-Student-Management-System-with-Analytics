"""
IoT attendance event simulator for the Smart Student Management System.

This script creates semi-structured attendance sensor events and:
1. prints them to stdout,
2. optionally writes them to a JSON file,
3. optionally inserts them into MongoDB if pymongo is installed and a URI is provided.

Usage examples:
    python scripts/iot_attendance_simulation.py
    python scripts/iot_attendance_simulation.py --count 10 --output attendance_events.json
    python scripts/iot_attendance_simulation.py --mongo-uri mongodb://localhost:27017/
"""

from __future__ import annotations

import argparse
import json
import random
from dataclasses import asdict, dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List, Optional


STUDENTS = [
    ("22CSE001", 1, 1, "RFID-CS301-A", "RFID"),
    ("22CSE002", 1, 1, "RFID-CS301-A", "RFID"),
    ("22CSE003", 1, 2, "RFID-CS301-A", "RFID"),
    ("22ECE001", 3, 3, "BLE-EC201-A", "BLE"),
]


@dataclass
class AttendanceEvent:
    event_id: str
    offering_id: int
    session_id: int
    student_roll: str
    device_id: str
    event_type: str
    detection_mode: str
    signal_strength: int
    battery_level: int
    confidence_score: float
    gate_name: str
    event_ts: str
    metadata: dict


def build_event(index: int) -> AttendanceEvent:
    student_roll, offering_id, session_id, device_id, detection_mode = random.choice(STUDENTS)
    base = datetime(2025, 8, 1, 4, 25, tzinfo=timezone.utc)
    event_ts = base + timedelta(minutes=random.randint(0, 180), seconds=random.randint(0, 59))
    gate_name = "Block-B Gate 2" if offering_id == 1 else "Block-E Lab Entry"

    return AttendanceEvent(
        event_id=f"EVT-SIM-{1000 + index}",
        offering_id=offering_id,
        session_id=session_id,
        student_roll=student_roll,
        device_id=device_id,
        event_type="CHECK_IN",
        detection_mode=detection_mode,
        signal_strength=random.randint(-65, -38),
        battery_level=random.randint(70, 98),
        confidence_score=round(random.uniform(92.5, 99.8), 2),
        gate_name=gate_name,
        event_ts=event_ts.isoformat(),
        metadata={
            "firmware_version": random.choice(["v1.4.2", "v1.5.0", "v2.1.0"]),
            "network_status": random.choice(["ONLINE", "ONLINE", "ONLINE", "FLAKY"]),
            "ingested_by": "iot_attendance_simulation.py",
        },
    )


def export_events(events: List[AttendanceEvent], output_path: Optional[Path]) -> None:
    payload = [asdict(event) for event in events]
    print(json.dumps(payload, indent=2))
    if output_path:
        output_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def insert_into_mongodb(events: List[AttendanceEvent], mongo_uri: str, db_name: str, collection_name: str) -> None:
    try:
        from pymongo import MongoClient
    except ImportError:
        print("pymongo is not installed; skipping MongoDB insert.")
        return

    client = MongoClient(mongo_uri)
    collection = client[db_name][collection_name]
    docs = [asdict(event) for event in events]
    collection.insert_many(docs)
    print(f"Inserted {len(docs)} events into MongoDB collection {db_name}.{collection_name}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate IoT attendance events")
    parser.add_argument("--count", type=int, default=5, help="Number of events to generate")
    parser.add_argument("--output", type=Path, help="Optional JSON output file")
    parser.add_argument("--mongo-uri", help="Optional MongoDB URI")
    parser.add_argument("--db-name", default="smart_student_management", help="MongoDB database name")
    parser.add_argument("--collection", default="attendance_events", help="MongoDB collection name")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    events = [build_event(i) for i in range(1, args.count + 1)]
    export_events(events, args.output)

    if args.mongo_uri:
        insert_into_mongodb(events, args.mongo_uri, args.db_name, args.collection)


if __name__ == "__main__":
    random.seed(42)
    main()
