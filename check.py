# check_pgversion_le.py
import struct
import sys

if len(sys.argv) != 2:
    print("Usage: python3 check_pgversion_le.py <path-to-dump>")
    sys.exit(1)

path = sys.argv[1]
with open(path, "rb") as f:
    sig = f.read(5)
    if sig != b"PGDMP":
        print("→ Not a PostgreSQL custom-format dump (signature mismatch).")
        sys.exit(1)

    dumpfmt = f.read(1)
    if len(dumpfmt) < 1:
        print("→ File too short or invalid.")
        sys.exit(1)
    dumpfmt_int = dumpfmt[0]

    ver_bytes = f.read(4)
    if len(ver_bytes) < 4:
        print("→ File too short or invalid.")
        sys.exit(1)

    # Try little-endian unpack
    pgver_le = struct.unpack("<I", ver_bytes)[0]
    pub_major_le = pgver_le // 100
    pub_minor_le = pgver_le % 100

    # Also show big-endian interpretation for comparison
    pgver_be = struct.unpack(">I", ver_bytes)[0]
    pub_major_be = pgver_be // 100
    pub_minor_be = pgver_be % 100

print(f"Signature: {sig!r}")
print(f"Dump-format flags (1=custom): {dumpfmt_int}")
print(f"Little-endian  pg_dump version int: {pgver_le}  →  Postgres {pub_major_le}.{pub_minor_le}")
print(f"Big-endian     pg_dump version int: {pgver_be}  →  Postgres {pub_major_be}.{pub_minor_be}")
