"""Build the pinned upstream Quirrel CLI with GCC for the regression harness."""
from pathlib import Path
import argparse
import subprocess

QUIRREL_COMMIT = "19f17df9b6ee43c91ef5c635fd45970ec76c5dbe"
parser = argparse.ArgumentParser()
parser.add_argument("--source", type=Path, required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()
source = args.source.resolve()
output = args.output.resolve()
if not source.exists():
    subprocess.run(["git", "clone", "https://github.com/GaijinEntertainment/quirrel.git", str(source)], check=True)
    subprocess.run(["git", "checkout", QUIRREL_COMMIT], cwd=source, check=True)
revision = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
if revision != QUIRREL_COMMIT:
    raise RuntimeError(f"Expected Quirrel {QUIRREL_COMMIT}, got {revision}")
sources = [str(p.relative_to(source)) for p in (source / "squirrel").glob("*.cpp")
           if p.name != "vartrace.cpp"]
sources += [str(p.relative_to(source)) for p in (source / "squirrel" / "compiler").rglob("*.cpp")]
sources += [str(p.relative_to(source)) for directory in ["sqstdlib", "sqmodules", "sq"]
            for p in (source / directory).glob("*.cpp")]
output.parent.mkdir(parents=True, exist_ok=True)
subprocess.run([
    "g++", "-std=c++17", "-O0", "-D_SQ64", "-DSQ_VAR_TRACE_ENABLED=0", "-fno-rtti",
    "-I.", "-Iinclude", "-Isqrat/include", "-Isquirrel", "-Isquirrel/compiler",
    "-Isqmodules", "-Iinternal", "-Ihelpers", *sorted(sources), "-o", str(output)
], cwd=source, check=True)
