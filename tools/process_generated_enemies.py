from pathlib import Path
from PIL import Image

source = Image.open("tmp/imagegen/enemy_atlas_alpha.png").convert("RGBA")
output = Path("assets/generated/enemies")
output.mkdir(parents=True, exist_ok=True)
names = ["gloomling", "shellsnout", "wisp", "mender", "corruption_colossus"]

for index, name in enumerate(names):
    left = round(index * source.width / 5)
    right = round((index + 1) * source.width / 5)
    cell = source.crop((left, 0, right, source.height))
    bbox = cell.getchannel("A").getbbox()
    if bbox:
        cell = cell.crop(bbox)
    cell.thumbnail((340, 340), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (384, 384), (0, 0, 0, 0))
    canvas.alpha_composite(cell, ((384 - cell.width) // 2, 384 - cell.height - 8))
    canvas.save(output / f"{name}.png", optimize=True)

print(f"Wrote {len(names)} transparent enemy sprites to {output}")
