"""Execute real module code under Quirrel with a documented-SDK mock."""
from pathlib import Path
import subprocess
import tempfile
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("quirrel", help="Path to the Quirrel sq CLI executable")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
module = root / "Modules" / "SiegeGamemodes"
source = (module / "main.nut").read_text()
sdk_import = 'local { Game, Renderer } = require("HeatedMetal");\n'
if not source.startswith(sdk_import):
    raise RuntimeError("Module SDK import changed; update the test harness")
combined = (root / "tests" / "mock.nut").read_text() + "\n"
combined += source[len(sdk_import):] + "\n"
combined += (root / "tests" / "scenarios.nut").read_text()
with tempfile.NamedTemporaryFile(mode="w", suffix=".nut", dir=module, delete=False) as file:
    file.write(combined)
    path = Path(file.name)
try:
    result = subprocess.run([str(Path(args.quirrel).resolve()), str(path)], cwd=module,
                            text=True, capture_output=True)
    print(result.stdout)
    if result.stderr:
        print(result.stderr)
    result.check_returncode()
    if "Quirrel regression checks" not in result.stdout or "PASS:" not in result.stdout:
        raise RuntimeError("Quirrel did not reach the end of the regression suite")
finally:
    path.unlink()
