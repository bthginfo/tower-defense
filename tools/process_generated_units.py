from pathlib import Path
from PIL import Image

SOURCE = Path("tmp/imagegen/unit_atlas_alpha.png")
OUTPUT = Path("assets/generated/units")
NAMES = [
    "bramble_bun", "cinder_fox", "brook_otter", "gale_finch",
    "moss_guardian", "fizzlepaw", "moon_moth", "pollen_pixie",
    "coal_badger", "tempest_lynx", "tidecaller_toad", "starhorn_stag",
]

atlas = Image.open(SOURCE).convert("RGBA")
cell_w, cell_h = atlas.width // 4, atlas.height // 3
OUTPUT.mkdir(parents=True, exist_ok=True)

for index, name in enumerate(NAMES):
    col, row = index % 4, index // 4
    cell = atlas.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
    alpha = cell.getchannel("A")
    bbox = alpha.getbbox()
    if bbox:
        cell = cell.crop(bbox)
    cell.thumbnail((340, 340), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    canvas.alpha_composite(cell, ((384 - cell.width) // 2, 384 - cell.height - 8))
    canvas.save(OUTPUT / f"{name}.png", optimize=True)

print(f"Wrote {len(NAMES)} transparent unit sprites to {OUTPUT}")
