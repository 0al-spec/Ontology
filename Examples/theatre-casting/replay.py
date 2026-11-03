"""Replay the synthetic theatre appointments through ontologyc and query their history."""

import json
import subprocess
import sys
import tempfile
from copy import deepcopy
from pathlib import Path

EXAMPLE = Path(__file__).resolve().parent
ONTOLOGY = EXAMPLE.parents[1] / "SPECS/ontology"
IR = ONTOLOGY / "packages/events-core/generated/ontology.normalized.json"


def validate(compiler, graph, directory, expected_codes):
    source = directory / "input.json"
    report = directory / "report.json"
    source.write_text(json.dumps(graph), encoding="utf-8")
    report.unlink(missing_ok=True)
    result = subprocess.run(
        [compiler, "validate-instances", source, "--ontology-ir", IR, "--out", report],
        capture_output=True, text=True,
    )
    data = json.loads(report.read_text())
    codes = [item["code"] for item in data["diagnostics"]]
    if result.returncode != int(bool(expected_codes)) or codes != expected_codes:
        raise ValueError((result.returncode, codes, result.stderr))
    if data["authority"]["sourceTruthVerified"] is not False:
        raise ValueError("Unexpected source truth claim")


def exactly_one(matches, subject, relation):
    if len(matches) != 1:
        raise ValueError(f"{subject}: expected one eventcore:{relation} edge, found {len(matches)}")
    return matches[0]


def appointments(graph):
    nodes = {node["id"]: node for node in graph["nodes"]}

    def targets(subject, relation):
        return [edge["to"]["nodeId"] for edge in graph["edges"]
                if edge["relation"] == "eventcore:" + relation and edge["from"]["nodeId"] == subject]

    def one_target(subject, relation):
        return exactly_one(targets(subject, relation), subject, relation)

    history = []
    for view in graph["nodes"]:
        if view["type"] != "eventcore:Interpretation":
            continue
        record = one_target(view["id"], "interpretsRecord")
        roles = {}
        for binding in targets(view["id"], "interpretationBindsRole"):
            entity = one_target(binding, "roleBoundEntity")
            roles[nodes[binding]["fields"]["roleName"]] = entity
        snapshot = one_target(record, "recordAfterSnapshot")
        fact = one_target(snapshot, "snapshotContainsFact")
        history.append((nodes[record]["fields"]["intervalStart"], roles["actor"],
                        roles["appointee"], roles["slot"], nodes[fact]["fields"]["propositionKey"]))
    return sorted(history)


def main(compiler):
    subprocess.run([compiler, "check", ONTOLOGY / "examples/theatre.yaml"], check=True)
    graph = json.loads((EXAMPLE / "appointments.json").read_text())
    with tempfile.TemporaryDirectory() as temp:
        directory = Path(temp)
        validate(compiler, graph, directory, [])
        slot = "show-17-hamlet"
        expected = [(1793696400, "ivan", "anna", slot, slot + "-occupancy-anna"),
                    (1793700000, "ivan", "boris", slot, slot + "-occupancy-boris")]
        if appointments(graph) != expected:
            raise ValueError("Unexpected appointments or observed occupancy")

        incomplete = deepcopy(graph)
        incomplete["edges"] = [e for e in incomplete["edges"]
                               if not (e["from"]["nodeId"] == "delta-assign-2"
                                       and e["relation"] == "eventcore:deltaRemovesFact")]
        validate(compiler, incomplete, directory, ["instanceGraph.delta.exact"])

        alternative = deepcopy(graph)
        actor_edges = [e for e in alternative["edges"] if e["from"]["nodeId"] == "assign-1-actor"
                       and e["relation"] == "eventcore:roleBoundEntity"]
        actor_edge = exactly_one(actor_edges, "assign-1-actor", "roleBoundEntity")
        actor_edge["to"]["nodeId"] = "ghost"
        validate(compiler, alternative, directory, ["instanceGraph.ref.missing"])
        actor_edge["to"]["nodeId"] = "boris"
        validate(compiler, alternative, directory, [])
    print("Current occupant: Boris. First appointment: Ivan appointed Anna at 09:00 UTC.")


if __name__ == "__main__":
    main(sys.argv[1])
