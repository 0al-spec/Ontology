"""Small image-domain example; observations and goal completion stay separate."""

from dataclasses import dataclass
from hashlib import sha256
from io import BytesIO
from pathlib import Path
from tempfile import NamedTemporaryFile

from PIL import Image


def _nonnegative_integer(name: str, value: int) -> None:
    if type(value) is not int or value < 0:
        raise ValueError(f"{name} must be a nonnegative integer, excluding bool")


def _entity_id(value: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise ValueError("entity_id must be a nonempty string")


@dataclass(frozen=True)
class ImageState:
    entity_id: str
    byte_length: int
    width: int
    height: int
    content_sha256: str

    def __post_init__(self) -> None:
        _entity_id(self.entity_id)
        for name in ("byte_length", "width", "height"):
            _nonnegative_integer(name, getattr(self, name))
        if (
            not isinstance(self.content_sha256, str)
            or len(self.content_sha256) != 64
            or any(char not in "0123456789abcdef" for char in self.content_sha256)
        ):
            raise ValueError("content_sha256 must be a lowercase SHA-256 hex digest")


@dataclass(frozen=True)
class ImageDocument:
    entity_id: str
    path: Path

    def __post_init__(self) -> None:
        _entity_id(self.entity_id)
        if not isinstance(self.path, Path):
            raise TypeError("path must be a pathlib.Path")

    def observe(self) -> ImageState:
        data = self.path.read_bytes()
        with Image.open(BytesIO(data)) as image:
            image.load()
            width, height = image.size
        return ImageState(self.entity_id, len(data), width, height, sha256(data).hexdigest())


@dataclass(frozen=True)
class Encoder:
    quality: int
    identity_mode: str = "in_place"
    dimensions: str = "preserve"

    def __post_init__(self) -> None:
        if type(self.quality) is not int or not 1 <= self.quality <= 95:
            raise ValueError("quality must be an integer from 1 to 95, excluding bool")
        if self.identity_mode not in ("in_place", "copy"):
            raise ValueError("identity_mode must be 'in_place' or 'copy'")
        if self.dimensions not in ("preserve", "resize"):
            raise ValueError("dimensions must be 'preserve' or 'resize'")

    def reencode(self, document: ImageDocument) -> ImageDocument:
        """Encode JPEG pixels; resize halves dimensions with a one-pixel minimum.

        JPEG is lossy, metadata is not preserved, and no size reduction is promised.
        In-place replacement preserves the declared entity ID and path, not inode.
        """
        if not isinstance(document, ImageDocument):
            raise TypeError("document must be an ImageDocument")
        with Image.open(document.path) as source:
            source.load()
            pixels = source.convert("RGB")
        try:
            if self.dimensions == "resize":
                resized = pixels.resize(
                    (max(1, pixels.width // 2), max(1, pixels.height // 2)),
                    Image.Resampling.LANCZOS,
                )
                pixels.close()
                pixels = resized
            encoded = BytesIO()
            pixels.save(encoded, format="JPEG", quality=self.quality)
        finally:
            pixels.close()

        temporary = None
        try:
            prefix = f"{document.path.stem}-copy-" if self.identity_mode == "copy" else ".encode-"
            with NamedTemporaryFile(
                mode="wb", prefix=prefix, suffix=".jpg", dir=document.path.parent, delete=False
            ) as output:
                temporary = Path(output.name)
                output.write(encoded.getvalue())
            if self.identity_mode == "in_place":
                temporary.replace(document.path)
                return ImageDocument(document.entity_id, document.path)
            return ImageDocument(f"{document.entity_id}-copy-{temporary.stem}", temporary)
        except BaseException:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
            raise


@dataclass(frozen=True)
class SizeGoal:
    basis: str
    comparison: str
    target_bytes: int
    missing_input: str = "unknown"

    def __post_init__(self) -> None:
        if self.basis not in ("reduction", "final_size"):
            raise ValueError("basis must be 'reduction' or 'final_size'")
        if self.comparison not in ("at_least", "exactly", "at_most"):
            raise ValueError("comparison must be 'at_least', 'exactly', or 'at_most'")
        _nonnegative_integer("target_bytes", self.target_bytes)
        if self.missing_input != "unknown":
            raise ValueError("missing_input must be 'unknown'")

    def evaluate(self, before: ImageState | None, after: ImageState | None) -> str:
        for state in (before, after):
            if state is not None and not isinstance(state, ImageState):
                raise TypeError("before and after must be ImageState values or None")
        if after is None:
            return "unknown"
        if self.basis == "reduction":
            if before is None or before.entity_id != after.entity_id:
                return "unknown"
            observed = before.byte_length - after.byte_length
        else:
            observed = after.byte_length
        if self.comparison == "at_least":
            satisfied = observed >= self.target_bytes
        elif self.comparison == "exactly":
            satisfied = observed == self.target_bytes
        else:
            satisfied = observed <= self.target_bytes
        return "satisfied" if satisfied else "not_satisfied"
