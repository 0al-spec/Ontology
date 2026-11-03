"""Exercise the public package checker and inspect the action identity in compiled IR."""

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory

PACKAGE = Path(__file__).resolve().parents[2] / "SPECS/ontology/examples/appointments.yaml"


def verify_endpoints(compiler, directory, source, ir):
    legacy = directory / "legacy.yaml"
    legacy.write_text(source.replace("subject: Person", "domain: Person").replace("object: Person", "range: Person"))
    legacy_sdk = directory / "legacy-sdk"
    subprocess.run([compiler, "compile", legacy, "--target", "typescript", "--out", legacy_sdk], check=True)
    other = json.loads((legacy_sdk / "ontology.normalized.json").read_text())
    if ir["relations"] != other["relations"] or ir["sourceDigest"] == other["sourceDigest"]:
        raise ValueError("The two spellings must have identical relation bindings and distinct source digests")

    prefix = "spec.relations.CastAppointment"
    declaration = "CastAppointment: {subject: Person, action: Appoint, object: Person}"
    controls = [
        ("subject: Missing, action: Appoint, object: Person", ".subject", "relation.subject.unresolved"),
        ("subject: Person, action: Appoint, object: {oneOf: [Person, Missing]}", ".object.oneOf[1]", "relation.object.unresolved"),
        ("subject: Person, object: Person", ".action", "relation.action.required"),
        ("subject: Person, action: Appoint", ".object", "relation.object.required"),
        ("subject: Person, action: Appoint, range: Person", "", "relation.endpoints.mixed"),
        ("subject: Person, domain: Person, action: Appoint, object: Person", "", "relation.endpoints.mixed"),
    ]
    for fields, location, code in controls:
        candidate = directory / "invalid-endpoints.yaml"
        candidate.write_text(source.replace(declaration, "CastAppointment: {" + fields + "}"))
        result = subprocess.run([compiler, "check", candidate, "--format", "json"], capture_output=True, text=True)
        issues = [(d["path"], d["code"]) for d in json.loads(result.stdout)]
        if result.returncode != 1 or issues != [(prefix + location, code)]:
            raise ValueError((fields, result.returncode, issues))


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
    verify_endpoints(compiler, directory, source, ir)
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
