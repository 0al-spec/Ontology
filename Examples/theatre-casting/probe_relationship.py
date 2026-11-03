"""Exercise the public package checker and inspect the action identity in compiled IR."""

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

PACKAGE = Path(__file__).resolve().parents[2] / "SPECS/ontology/examples/appointments.yaml"


def verify(compiler, directory):
    subprocess.run([compiler, "check", PACKAGE], check=True)
    output = directory / "sdk"
    subprocess.run([compiler, "compile", PACKAGE, "--target", "typescript", "--out", output],
                   check=True)
    ir = json.loads((output / "ontology.normalized.json").read_text())
    actions = {relation["id"]: relation["action"] for relation in ir["relations"] if "action" in relation}
    expected = {"CastAppointment": "pilot:Appoint", "CrewAppointment": "pilot:Appoint",
                "CastCancellation": "pilot:Cancel"}
    if actions != expected:
        raise ValueError(f"Incorrect action references: {actions}")

    source = PACKAGE.read_text()
    for name, code in [("Appiont", "relation.action.unresolved"),
                       ("Person", "relation.action.wrong_kind")]:
        invalid = directory / (name + ".yaml")
        invalid.write_text(source.replace("action: Appoint", "action: " + name))
        check = subprocess.run([compiler, "check", invalid, "--format", "json"],
                               capture_output=True, text=True)
        diagnostics = [(d["path"], d["code"]) for d in json.loads(check.stdout)]
        if check.returncode != 1 or sorted(diagnostics) != [
            ("spec.relations.CastAppointment.action", code),
            ("spec.relations.CrewAppointment.action", code),
        ]:
            raise ValueError((name, check.returncode, diagnostics))
        print(f"{name}: {code} at both appointment declarations")


if __name__ == "__main__":
    with TemporaryDirectory() as temp:
        verify(sys.argv[1], Path(temp))
