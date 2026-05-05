use smart_student_management;

db.createCollection("attendance_events");

db.attendance_events.createIndex(
  { event_ts: 1, offering_id: 1, student_roll: 1 },
  { name: "idx_event_ts_offering_student" }
);

db.attendance_events.insertMany([
  {
    event_id: "EVT-1001",
    offering_id: 1,
    session_id: 1,
    student_roll: "22CSE001",
    device_id: "RFID-CS301-A",
    event_type: "CHECK_IN",
    detection_mode: "RFID",
    signal_strength: -41,
    battery_level: 92,
    confidence_score: 99.2,
    gate_name: "Block-B Gate 2",
    event_ts: ISODate("2025-08-01T04:28:11Z"),
    metadata: {
      firmware_version: "v1.4.2",
      network_status: "ONLINE"
    }
  },
  {
    event_id: "EVT-1002",
    offering_id: 1,
    session_id: 1,
    student_roll: "22CSE002",
    device_id: "RFID-CS301-A",
    event_type: "CHECK_IN",
    detection_mode: "RFID",
    signal_strength: -44,
    battery_level: 92,
    confidence_score: 98.8,
    gate_name: "Block-B Gate 2",
    event_ts: ISODate("2025-08-01T04:29:44Z"),
    metadata: {
      firmware_version: "v1.4.2",
      network_status: "ONLINE"
    }
  },
  {
    event_id: "EVT-1003",
    offering_id: 3,
    session_id: 3,
    student_roll: "22ECE001",
    device_id: "BLE-EC201-A",
    event_type: "CHECK_IN",
    detection_mode: "BLE",
    signal_strength: -55,
    battery_level: 88,
    confidence_score: 95.7,
    gate_name: "Block-E Lab Entry",
    event_ts: ISODate("2025-08-02T08:28:22Z"),
    metadata: {
      firmware_version: "v2.1.0",
      network_status: "ONLINE"
    }
  }
]);

// Example aggregation: daily presence count by course offering
db.attendance_events.aggregate([
  {
    $group: {
      _id: {
        offering_id: "$offering_id",
        session_id: "$session_id",
        day: {
          $dateToString: { format: "%Y-%m-%d", date: "$event_ts" }
        }
      },
      attendance_events: { $sum: 1 },
      avg_confidence: { $avg: "$confidence_score" }
    }
  },
  { $sort: { "_id.day": 1, "_id.offering_id": 1 } }
]);
