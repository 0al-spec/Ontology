"""Print ontologyc results for the proposed action slot and a class-based encoding.

Run with a built ontologyc. This exploratory probe is independent of CI because
introducing an action slot should change the observed results.
"""

import json
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory


def domain_class(base, description):
    return {"extends": base, "description": description}


def package(reify=False, target="Appoint", include_action=True):
    classes = {
        "Person": domain_class("ont:DomainEntity", "A person."),
        "Appoint": domain_class("ont:Command", "The intentional act of appointing."),
    }
    relations = {}
    for context in ("Cast", "Crew"):
        name = context + "Appointment"
        if reify:
            classes[name] = domain_class("ont:DomainEntity", "An appointment in this context.")
            for slot, entity in (("Subject", "Person"), ("Object", "Person"), ("Action", target)):
                relations[name + slot] = {"domain": name, "range": entity,
                                          "cardinality": {"min": 1, "max": 1}}
        else:
            relations[name] = {"domain": "Person", "range": "Person"}
            if include_action:
                relations[name]["action"] = target
    return {
        "apiVersion": "ontology.specgraph.io/v1alpha1",
        "kind": "DomainOntologyPackage",
        "metadata": {"id": "org.example.appointments", "namespace": "pilot", "version": "0.1.0",
                     "publisher": "TheatrePilot", "source": "probe_relationship.py",
                     "approvalStatus": "draft"},
        "spec": {"imports": [{"id": "ontology.foundation", "namespace": "ont", "version": "0.2.0"}],
                 "classes": classes, "relations": relations},
    }


def probe(compiler, directory, label, data):
    source = directory / (label + ".yaml")
    source.write_text(json.dumps(data, indent=2), encoding="utf-8")
    check = subprocess.run([compiler, "check", source, "--format", "json"],
                           capture_output=True, text=True)
    if check.returncode not in (0, 1):
        raise RuntimeError(check.stderr or check.stdout)
    print(label, "exit", check.returncode, flush=True)
    for finding in json.loads(check.stdout):
        print(" ", finding["code"], finding["path"])
    if check.returncode:
        return
    out = directory / label
    subprocess.run([compiler, "compile", source, "--target", "typescript", "--out", out],
                   check=True, stdout=subprocess.DEVNULL)
    ir = json.loads((out / "ontology.normalized.json").read_text())
    for relation in ir["relations"]:
        print(" ", relation["id"], relation["domain"], "->", relation["range"],
              "action:", relation.get("action"))


def main(compiler):
    with TemporaryDirectory() as temp:
        directory = Path(temp)
        for label, data in [
            ("binary", package(include_action=False)),
            ("direct", package()), ("direct-typo", package(target="Appiont")),
            ("reified", package(reify=True)), ("reified-typo", package(True, "Appiont")),
            ("reified-person", package(True, "Person")),
        ]:
            probe(compiler, directory, label, data)


if __name__ == "__main__":
    main(sys.argv[1])
