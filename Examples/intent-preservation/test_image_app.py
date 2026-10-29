"""Domain checks use generated disposable images, never user image files."""

from dataclasses import FrozenInstanceError
from hashlib import sha256
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from hypothesis import given, strategies as st
from PIL import Image, UnidentifiedImageError

from image_app import Encoder, ImageDocument, ImageState, SizeGoal


def state(byte_length: int, entity_id: str = "selected-image") -> ImageState:
    return ImageState(entity_id, byte_length, 8, 6, "0" * 64)


def jpeg(path: Path, size: tuple[int, int] = (31, 23)) -> ImageDocument:
    with Image.new("RGB", size) as pixels:
        pixels.putdata([
            ((index * 73) % 256, (index * 137) % 256, (index * 193) % 256)
            for index in range(size[0] * size[1])
        ])
        pixels.save(path, format="JPEG", quality=95)
    return ImageDocument("selected-image", path)


class ImageDocumentTests(unittest.TestCase):
    def test_construction_does_not_read_a_file(self):
        with TemporaryDirectory() as directory:
            document = ImageDocument("image", Path(directory) / "missing.jpg")
            self.assertEqual(document.entity_id, "image")
            with self.assertRaises(FileNotFoundError):
                document.observe()

    def test_observation_uses_actual_bytes_and_decoded_dimensions(self):
        with TemporaryDirectory() as directory:
            document = jpeg(Path(directory) / "image.jpg")
            observed = document.observe()
            data = document.path.read_bytes()
            self.assertEqual(observed, ImageState(
                document.entity_id, len(data), 31, 23, sha256(data).hexdigest()
            ))

    def test_in_place_preserves_entity_path_and_dimensions(self):
        with TemporaryDirectory() as directory:
            document = jpeg(Path(directory) / "image.jpg")
            before = document.observe()
            result = Encoder(quality=40).reencode(document)
            after = result.observe()
            self.assertIsNot(result, document)
            self.assertEqual(result, document)
            self.assertEqual(after.entity_id, before.entity_id)
            self.assertEqual((after.width, after.height), (before.width, before.height))
            self.assertEqual(after.byte_length, len(result.path.read_bytes()))
            self.assertEqual(after.content_sha256, sha256(result.path.read_bytes()).hexdigest())
            self.assertNotEqual(after.content_sha256, before.content_sha256)
            self.assertEqual(list(Path(directory).iterdir()), [document.path])

    def test_copy_creates_distinct_entities_and_preserves_source(self):
        with TemporaryDirectory() as directory:
            document = jpeg(Path(directory) / "image.jpg")
            before = document.observe()
            first = Encoder(quality=40, identity_mode="copy").reencode(document)
            second = Encoder(quality=40, identity_mode="copy").reencode(document)
            self.assertEqual(document.observe(), before)
            self.assertEqual(first.path.parent, document.path.parent)
            self.assertNotEqual(first.path, document.path)
            self.assertEqual(len({document.entity_id, first.entity_id, second.entity_id}), 3)
            self.assertEqual(len({document.path, first.path, second.path}), 3)
            self.assertEqual((first.observe().width, first.observe().height), (31, 23))

    def test_resize_halves_dimensions_without_zero_pixels(self):
        for size, expected in (((31, 23), (15, 11)), ((1, 1), (1, 1))):
            with self.subTest(size=size), TemporaryDirectory() as directory:
                document = jpeg(Path(directory) / "image.jpg", size)
                result = Encoder(quality=40, dimensions="resize").reencode(document)
                observed = result.observe()
                self.assertEqual((observed.width, observed.height), expected)
                self.assertEqual(result.entity_id, document.entity_id)

    def test_bad_image_preserves_original_and_leaves_no_output(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / "invalid.jpg"
            path.write_bytes(b"not an image")
            with self.assertRaises(UnidentifiedImageError):
                Encoder(quality=40).reencode(ImageDocument("image", path))
            self.assertEqual(path.read_bytes(), b"not an image")
            self.assertEqual(list(Path(directory).iterdir()), [path])


class ValueValidationTests(unittest.TestCase):
    def test_values_are_frozen(self):
        values = (
            (state(10), "byte_length", 20),
            (ImageDocument("image", Path("absent.jpg")), "entity_id", "other"),
            (Encoder(40), "quality", 80),
            (SizeGoal("reduction", "at_least", 10), "target_bytes", 20),
        )
        for value, field, replacement in values:
            with self.subTest(value=value), self.assertRaises(FrozenInstanceError):
                setattr(value, field, replacement)

    def test_sizes_and_targets_reject_invalid_numbers(self):
        for invalid in (-1, True, False, 1.5, "10", None):
            for field in ("byte_length", "width", "height"):
                values = dict(entity_id="image", byte_length=1, width=1, height=1,
                              content_sha256="0" * 64)
                values[field] = invalid
                with self.subTest(field=field, invalid=invalid), self.assertRaises(ValueError):
                    ImageState(**values)
            with self.subTest(target=invalid), self.assertRaises(ValueError):
                SizeGoal("reduction", "at_least", invalid)
        self.assertEqual(state(0).byte_length, 0)
        self.assertEqual(SizeGoal("reduction", "at_least", 0).target_bytes, 0)

    def test_quality_bounds_are_explicit(self):
        for invalid in (0, 96, -1, True, False, 1.5, "40", None):
            with self.subTest(invalid=invalid), self.assertRaises(ValueError):
                Encoder(invalid)
        self.assertEqual(Encoder(1).quality, 1)
        self.assertEqual(Encoder(95).quality, 95)

    def test_unknown_modes_and_goals_are_rejected(self):
        constructors = (
            lambda: Encoder(40, identity_mode="move"),
            lambda: Encoder(40, dimensions="crop"),
            lambda: SizeGoal("ratio", "at_least", 10),
            lambda: SizeGoal("reduction", "approximately", 10),
            lambda: SizeGoal("reduction", "at_least", 10, "satisfied"),
        )
        for constructor in constructors:
            with self.subTest(constructor=constructor), self.assertRaises(ValueError):
                constructor()

    def test_identity_path_and_digest_validation(self):
        for invalid in ("", " ", None, 3):
            with self.subTest(entity_id=invalid), self.assertRaises(ValueError):
                ImageDocument(invalid, Path("image.jpg"))
        with self.assertRaises(TypeError):
            ImageDocument("image", "image.jpg")
        for invalid in ("", "0" * 63, "G" * 64, "a" * 64 + "\n", None):
            with self.subTest(digest=invalid), self.assertRaises(ValueError):
                ImageState("image", 0, 0, 0, invalid)


class SizeGoalProperties(unittest.TestCase):
    @given(st.integers(min_value=1), st.integers(min_value=0))
    def test_reduction_at_least_boundary(self, target, final_size):
        goal = SizeGoal("reduction", "at_least", target)
        self.assertEqual(goal.evaluate(state(final_size + target), state(final_size)), "satisfied")
        self.assertEqual(goal.evaluate(state(final_size + target - 1), state(final_size)),
                         "not_satisfied")
        self.assertEqual(goal.evaluate(state(final_size + target + 1), state(final_size)), "satisfied")

    @given(st.integers(min_value=0), st.integers(min_value=0), st.integers(min_value=0),
           st.sampled_from(("reduction", "final_size")),
           st.sampled_from(("at_least", "exactly", "at_most")))
    def test_comparators_match_the_selected_numerical_basis(self, before, after, target,
                                                         basis, comparison):
        observed = before - after if basis == "reduction" else after
        expected = {"at_least": observed >= target, "exactly": observed == target,
                    "at_most": observed <= target}[comparison]
        result = SizeGoal(basis, comparison, target).evaluate(state(before), state(after))
        self.assertEqual(result, "satisfied" if expected else "not_satisfied")

    @given(st.integers(min_value=1), st.integers(min_value=0))
    def test_reduction_depends_on_baseline(self, target, final_size):
        goal = SizeGoal("reduction", "at_least", target)
        after = state(final_size)
        self.assertEqual(goal.evaluate(state(final_size + target), after), "satisfied")
        self.assertEqual(goal.evaluate(state(final_size), after), "not_satisfied")

    @given(st.integers(min_value=0), st.integers(min_value=0))
    def test_missing_required_observations_remain_unknown(self, size, target):
        for comparison in ("at_least", "exactly", "at_most"):
            reduction = SizeGoal("reduction", comparison, target)
            final_size = SizeGoal("final_size", comparison, target)
            for before, after in ((None, None), (state(size), None), (None, state(size))):
                self.assertEqual(reduction.evaluate(before, after), "unknown")
            self.assertEqual(final_size.evaluate(state(size), None), "unknown")
            self.assertEqual(final_size.evaluate(None, state(size)),
                             final_size.evaluate(state(size + 1), state(size)))

    @given(st.integers(min_value=0), st.integers(min_value=1))
    def test_growth_is_negative_reduction_without_clipping(self, before, growth):
        initial, final = state(before), state(before + growth)
        self.assertEqual(SizeGoal("reduction", "at_least", 0).evaluate(initial, final),
                         "not_satisfied")
        self.assertEqual(SizeGoal("reduction", "exactly", 0).evaluate(initial, final),
                         "not_satisfied")
        self.assertEqual(SizeGoal("reduction", "at_most", 0).evaluate(initial, final), "satisfied")

    @given(st.integers(min_value=0), st.integers(min_value=0))
    def test_reduction_requires_same_entity_but_final_size_does_not(self, before, after):
        initial, final = state(before), state(after, "another-image")
        self.assertEqual(SizeGoal("reduction", "at_least", 0).evaluate(initial, final), "unknown")
        self.assertEqual(SizeGoal("final_size", "exactly", after).evaluate(initial, final),
                         "satisfied")


if __name__ == "__main__":
    unittest.main()
