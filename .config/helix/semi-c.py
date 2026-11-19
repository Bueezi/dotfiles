#!/usr/bin/env python3
# Helix formatter for C/C++ (c or c++): stdin -> stdout with only clang's "expected ';'" fix-its applied.
# Clang stops after a few errors, hence the rounds
import os, re, subprocess, sys, tempfile

lang = sys.argv[1] if len(sys.argv) > 1 else "c"
src = sys.stdin.buffer.read()
out = src
fixit = re.compile(rb'^fix-it:".*":\{(\d+):(\d+)-(\d+):(\d+)\}:";"$')
wanted = re.compile(rb"error: expected ';'")
missing = re.compile(rb":(\d+):\d+: fatal error: '.*' file not found")

try:
    with tempfile.TemporaryDirectory() as d:
        path = os.path.join(d, "buffer.c" if lang == "c" else "buffer.cpp")
        blanked = set()   # lines of unfound #includes, blanked in the copy only
        for _ in range(50):
            lines = out.split(b"\n")
            parsed = b"\n".join(b"" if i + 1 in blanked else l for i, l in enumerate(lines))
            with open(path, "wb") as f:
                f.write(parsed)
            r = subprocess.run(["clang-check", path, "--", "-x", lang, "-I.", "-Iinclude",
                                "-fdiagnostics-parseable-fixits", "-fno-color-diagnostics"],
                               capture_output=True, timeout=20)
            diag = (r.stdout + r.stderr).split(b"\n")
            m = next((missing.search(l) for l in diag if missing.search(l)), None)
            if m and int(m.group(1)) not in blanked:
                blanked.add(int(m.group(1)))
                continue
            at, err = set(), b""
            for l in diag:
                if re.search(rb": (error|warning|note): ", l):
                    err = l
                f = fixit.match(l)
                if f and wanted.search(err) and f.group(1, 2) == f.group(3, 4):
                    at.add((int(f.group(1)), int(f.group(2))))
            if not at:
                break
            for line, col in sorted(at, reverse=True):   # from the end: earlier positions stay valid
                lines[line - 1] = lines[line - 1][:col - 1] + b";" + lines[line - 1][col - 1:]
            out = b"\n".join(lines)
except Exception:
    out = src   # anything odd (no clang-check, timeout): the buffer back untouched

sys.stdout.buffer.write(out)
