from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PUBSPEC = ROOT / "pubspec.yaml"


def registered_png_assets() -> list[Path]:
    assets: list[Path] = []
    for line in PUBSPEC.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.startswith("- assets/") and stripped.endswith(".png"):
            path = ROOT / stripped[2:].strip()
            if path.exists():
                assets.append(path)
    return assets


def main() -> None:
    assets = registered_png_assets()
    before = sum(path.stat().st_size for path in assets)
    changed = 0
    for path in assets:
        old_size = path.stat().st_size
        temp_path = path.with_name(f"{path.name}.optimized")
        with Image.open(path) as image:
            image.save(temp_path, format="PNG", optimize=True)
        if temp_path.stat().st_size < old_size:
            temp_path.replace(path)
            changed += 1
        else:
            temp_path.unlink(missing_ok=True)
    after = sum(path.stat().st_size for path in assets)
    print(
        "optimized={optimized} changed={changed} beforeMB={before:.2f} "
        "afterMB={after:.2f} savedMB={saved:.2f}".format(
            optimized=len(assets),
            changed=changed,
            before=before / 1024 / 1024,
            after=after / 1024 / 1024,
            saved=(before - after) / 1024 / 1024,
        )
    )


if __name__ == "__main__":
    main()
