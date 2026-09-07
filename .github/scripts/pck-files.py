"""Print the resource paths indexed in a Godot .pck, one per line.

Paths are listed exactly as the pack stores them, without the res:// prefix,
so a script becomes "client/ClientEntry.gd.remap". Grepping the pck bytes
instead would also match path strings referenced from inside other packed
resources, which is not the same question as what the pack contains.

Supports pack format 2, 3 and 4 (Godot 4.7 writes 4). Directory encryption is
not supported; the exports here are unencrypted.
"""

import struct
import sys

PACK_MAGIC = 0x43504447  # GDPC
PACK_DIR_ENCRYPTED = 1


def _read(f, fmt):
    return struct.unpack(fmt, f.read(struct.calcsize(fmt)))


def pck_paths(path):
    with open(path, "rb") as f:
        start = f.tell()
        magic, = _read(f, "<I")
        if magic != PACK_MAGIC:
            raise SystemExit(f"{path}: not a pck (magic {magic:08x})")

        version = _read(f, "<I")[0]
        _read(f, "<3I")  # engine major, minor, patch
        if version not in (2, 3, 4):
            raise SystemExit(f"{path}: unsupported pack format {version}")

        flags = _read(f, "<I")[0]
        if flags & PACK_DIR_ENCRYPTED:
            raise SystemExit(f"{path}: encrypted directory is not supported")
        _read(f, "<Q")  # file base

        if version >= 3:
            # The directory lives at its own offset, relative to the header.
            dir_offset = _read(f, "<Q")[0]
            f.seek(dir_offset + start)
        else:
            f.read(16 * 4)  # reserved

        count = _read(f, "<I")[0]
        paths = []
        for _ in range(count):
            name_length = _read(f, "<I")[0]
            raw = f.read(name_length)
            _read(f, "<QQ")  # offset, size
            f.read(16)  # md5
            _read(f, "<I")  # per-file flags
            paths.append(raw.rstrip(b"\0").decode("utf-8", "replace"))
        return paths


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: pck-files.py <file.pck>")
    for entry in sorted(pck_paths(sys.argv[1])):
        print(entry)
