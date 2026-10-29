"""Fresh execution of the fixed adapter snapshot; no data-supplied modules."""

import json
from pathlib import Path
import sys

# Python -I -B excludes CWD/PYTHONPATH; restore only the parent's fixed snapshot.
sys.path.insert(0, str(Path(__file__).resolve().parent))
import image_app
from contract import implementation_values, load
from observe import observe

if __name__ == "__main__":
    configuration, execution, result = map(Path, sys.argv[1:])
    report = observe(image_app, implementation_values(load(configuration)), execution)
    result.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
