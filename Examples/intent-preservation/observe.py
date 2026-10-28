"""Bounded behavioral probes on disposable fixtures; never a proof of source equivalence."""

from hashlib import sha256, shake_256
from io import BytesIO
from pathlib import Path
from tempfile import TemporaryDirectory

from PIL import Image, __version__ as pillow_version

from contract import BY_KEY, validate_values, worst


def _snapshot(path: Path, entity_id: str) -> dict:
    data = path.read_bytes()
    if path.stat().st_size != len(data):
        raise RuntimeError("file changed while being observed")
    with Image.open(BytesIO(data)) as image:
        image.load()
        with image.convert("RGB") as pixels:
            pixel_digest = sha256(pixels.tobytes()).hexdigest()
        return {"entity_id": entity_id, "path": str(path), "byte_length": len(data),
                "width": image.width, "height": image.height, "format": image.format,
                "content_sha256": sha256(data).hexdigest(), "pixel_sha256": pixel_digest}


def _fixture(path: Path, offset: int) -> None:
    size = (1024, 768)
    data = shake_256(f"intent-preservation-fixture:{offset}".encode()).digest(size[0] * size[1] * 3)
    with Image.frombytes("RGB", size, data) as image:
        image.save(path, format="JPEG", quality=95, comment=b"disposable source fixture")


def _reference(data: bytes, values: dict) -> bytes:
    with Image.open(BytesIO(data)) as source:
        pixels = source.convert("RGB")
    try:
        if values["dimensions"] == "resize":
            resized = pixels.resize((max(1, pixels.width // 2), max(1, pixels.height // 2)),
                                    Image.Resampling.LANCZOS)
            pixels.close()
            pixels = resized
        output = BytesIO()
        pixels.save(output, format="JPEG", quality=values["quality"])
        return output.getvalue()
    finally:
        pixels.close()


def _oracle(values: dict, before: dict | None, after: dict | None, target: int) -> str:
    if after is None:
        return "unknown"
    if values["goal_basis"] == "reduction":
        if before is None or before["entity_id"] != after["entity_id"]:
            return "unknown"
        measured = before["byte_length"] - after["byte_length"]
    else:
        measured = after["byte_length"]
    comparison = values["goal_comparison"]
    accepted = (measured >= target if comparison == "at_least" else
                measured == target if comparison == "exactly" else measured <= target)
    return "satisfied" if accepted else "not_satisfied"


def _state(module, observed: dict | None):
    return None if observed is None else module.ImageState(**{
        key: observed[key] for key in ("entity_id", "byte_length", "width", "height", "content_sha256")
    })


def _goal(module, values: dict, target: int):
    return module.SizeGoal(basis=values["goal_basis"], comparison=values["goal_comparison"],
                           target_bytes=target, missing_input=values["missing_input"])


def _goal_checks(module, values: dict, check) -> None:
    target = values["goal_bytes"]
    # Fixed raw numbers are the oracle inputs; implementation states are only inputs to the candidate.
    cases = [
        ("reduction below", 36 + target, 37, False),
        ("reduction boundary", 37 + target, 37, False),
        ("reduction above", 38 + target, 37, False),
        ("growth", 37, 38, False), ("unchanged", 37, 37, False),
        ("same final, other baseline", 137 + target, 37, False),
        ("final below", 83, max(0, target - 1), False),
        ("final boundary", 83, target, False), ("final above", 83, target + 1, False),
        ("final other baseline", 183, target, False),
        ("zero bytes", 0, 0, False), ("missing both", None, None, False),
        ("missing baseline", None, 37, False), ("missing result", 37, None, False),
        ("different entities", 37 + target, 37, True),
    ]
    rounds = [(target, cases)]
    if target != 0:
        rounds.append((0, [("zero target boundary", 37, 37, False),
                           ("zero target growth", 37, 38, False),
                           ("zero target reduction", 38, 37, False),
                           ("zero final", 37, 0, False),
                           ("zero target missing", None, None, False)]))
    total = 0
    for threshold, probes in rounds:
        goal = _goal(module, values, threshold)
        for label, initial, final, different_entity in probes:
            def raw(size, identity):
                return None if size is None else {"entity_id": identity, "byte_length": size,
                    "width": 8, "height": 6, "content_sha256": "0" * 64}
            before = raw(initial, "probe-image")
            after = raw(final, "other-image" if different_entity else "probe-image")
            expected = _oracle(values, before, after, threshold)
            actual = goal.evaluate(_state(module, before), _state(module, after))
            keys = ("missing_input",) if initial is None or final is None else (
                "goal_basis", "goal_comparison", "goal_bytes")
            for key in keys:
                check(key, actual == expected,
                      f"{label}, target={threshold}: expected {expected}, observed {actual}")
            total += 1
    for key in ("goal_basis", "goal_comparison", "goal_bytes", "missing_input"):
        check(key, True, f"Completed {total} bounded probes against independent arithmetic; "
                        "numerical probes jointly test basis, comparison and target.")


def observe(module, values: dict, directory: Path) -> dict:
    """Check configured behavior; compare config with intent in the caller.

    Only known example modules are appropriate. This function is not a sandbox.
    Fixtures are deleted on return; paths in snapshots identify the observed temporary files.
    """
    checks = {key: {"id": key, "status": "unknown", "detail": "Not observed."} for key in BY_KEY}
    report = {"status": "unknown", "checks": [], "goal_result": "unknown",
              "before": None, "after": None, "reduction_bytes": None}

    def check(key: str, passed: bool, detail: str) -> None:
        previous = checks[key]
        if previous["status"] == "violated":
            return
        checks[key] = {"id": key, "status": "satisfied" if passed else "violated", "detail": detail}

    missing = sorted(set(BY_KEY) - set(values))
    if missing:
        for item in checks.values():
            item["detail"] = "Runtime unavailable: missing config " + ", ".join(missing)
    else:
        try:
            validate_values(values)
            directory.mkdir(parents=True, exist_ok=True)
            with TemporaryDirectory(prefix="image-observation-", dir=directory) as temporary:
                root = Path(temporary)
                selected, decoy = root / "image-1.jpg", root / "decoy.jpg"
                _fixture(selected, 0)
                _fixture(decoy, 59)
                before = _snapshot(selected, values["selected_entity"])
                decoy_before = _snapshot(decoy, "decoy")
                report["before"] = before
                reference = _reference(selected.read_bytes(), values)
                document = module.ImageDocument(entity_id=values["selected_entity"], path=selected)
                encoder = module.Encoder(quality=values["quality"], identity_mode=values["identity"],
                                         dimensions=values["dimensions"])
                result = encoder.reencode(document)
                if not isinstance(result.path, Path) or result.path.resolve().parent != root.resolve():
                    raise RuntimeError("encoder returned a path outside the disposable fixture directory")
                after = _snapshot(result.path, result.entity_id)
                report["after"] = after
                source_after = _snapshot(selected, values["selected_entity"])
                decoy_after = _snapshot(decoy, "decoy")
                source_changed = source_after["content_sha256"] != before["content_sha256"]
                reference_matches = after["content_sha256"] == sha256(reference).hexdigest()
                selected_ok = (source_changed and result.path == selected if values["identity"] == "in_place"
                               else not source_changed and reference_matches and result.path not in (selected, decoy))
                check("selected_entity", selected_ok and reference_matches and decoy_after == decoy_before,
                      f"Selected fixture changed={source_changed}; decoy unchanged={decoy_after == decoy_before}; "
                      f"output matches selected-image reference={reference_matches}.")
                identity_ok = (result.entity_id == before["entity_id"] and result.path == selected
                    if values["identity"] == "in_place" else
                    bool(result.entity_id) and result.entity_id != before["entity_id"] and result.path not in (selected, decoy))
                check("identity", identity_ok, f"Configured {values['identity']}; returned entity={result.entity_id}, "
                      f"same path={result.path == selected}.")
                expected_size = (before["width"], before["height"])
                if values["dimensions"] == "resize":
                    expected_size = tuple(max(1, value // 2) for value in expected_size)
                check("dimensions", (after["width"], after["height"]) == expected_size,
                      f"Expected dimensions {expected_size}; observed {(after['width'], after['height'])}.")
                check("action", values["action"] == "jpeg_reencode" and after["format"] == "JPEG",
                      f"Independent decode reports {after['format']}.")
                check("quality", reference_matches,
                      f"Encoded bytes match independent Pillow {pillow_version} JPEG reference at quality "
                      f"{values['quality']}={reference_matches}; scoped codec comparison, not general equivalence.")
                if before["entity_id"] == after["entity_id"]:
                    report["reduction_bytes"] = before["byte_length"] - after["byte_length"]
                goal_result = _goal(module, values, values["goal_bytes"]).evaluate(
                    _state(module, before), _state(module, after))
                expected = _oracle(values, before, after, values["goal_bytes"])
                for key in ("goal_basis", "goal_comparison", "goal_bytes"):
                    check(key, goal_result == expected, f"Actual goal: expected {expected}, observed {goal_result}.")
                report["goal_result"] = expected
                if goal_result != expected:
                    report["evaluator_result"] = str(goal_result)
                _goal_checks(module, values, check)
        except Exception as error:
            detail = f"Runtime error: {type(error).__name__}: {str(error)[:500]}"
            for key, item in checks.items():
                if item["status"] == "unknown":
                    check(key, False, detail)
            # Even an error after successful checks must remain a visible failure.
            if not any(item["status"] == "violated" for item in checks.values()):
                check("goal_basis", False, detail)
    report["checks"] = list(checks.values())
    report["status"] = worst([item["status"] for item in report["checks"]])
    return report
