param([switch]$Force)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$cache = Join-Path $env:TEMP 'critter-covenant-assets'
$out = Join-Path $root 'assets\third_party\kenney'
$licenses = Join-Path $root 'LICENSES\third_party'
New-Item -ItemType Directory -Force $cache,$out,$licenses | Out-Null

$packs = @(
  @{ Id='ui-pack'; Url='https://kenney.nl/media/pages/assets/ui-pack/f651646eab-1718203990/kenney_ui-pack.zip' },
  @{ Id='animal-pack-remastered'; Url='https://kenney.nl/media/pages/assets/animal-pack-remastered/54a307a369-1774771709/kenney_animal-pack-remastered.zip' },
  @{ Id='tower-defense-kit'; Url='https://kenney.nl/media/pages/assets/tower-defense-kit/a402493eaa-1726471567/kenney_tower-defense-kit.zip' }
)
foreach($pack in $packs) {
  $zip = Join-Path $cache ($pack.Id + '.zip')
  $expanded = Join-Path $cache $pack.Id
  if($Force -or !(Test-Path $zip)) { curl.exe -L --fail --silent --show-error -o $zip $pack.Url }
  if($Force -or !(Test-Path $expanded)) { Expand-Archive -LiteralPath $zip -DestinationPath $expanded -Force }
  Write-Host "$($pack.Id): $((Get-FileHash $zip -Algorithm SHA256).Hash)"
}

$animals = 'rabbit','dog','duck','owl','bear','frog','fox','parrot','panda','snake','crocodile','moose'
$animalSource = Join-Path $cache 'animal-pack-remastered\PNG\Round (outline)'
$animalOut = Join-Path $out 'animals'
New-Item -ItemType Directory -Force $animalOut | Out-Null
foreach($name in $animals) {
  $source = Join-Path $animalSource ($name + '.png')
  if(Test-Path $source) { Copy-Item $source (Join-Path $animalOut ($name + '.png')) -Force }
}

$uiSource = Join-Path $cache 'ui-pack\PNG\Blue\Default'
$uiOut = Join-Path $out 'ui'
New-Item -ItemType Directory -Force $uiOut | Out-Null
'button_rectangle_depth_gradient.png','button_round_depth_gradient.png','panel_rectangle_depth.png','icon_outline_checkmark.png','icon_outline_cross.png' | ForEach-Object {
  $source = Join-Path $uiSource $_
  if(Test-Path $source) { Copy-Item $source (Join-Path $uiOut $_) -Force }
}
Copy-Item (Join-Path $cache 'animal-pack-remastered\License.txt') (Join-Path $licenses 'KENNEY_CC0.txt') -Force
$tdSource = Join-Path $cache 'tower-defense-kit\Models\GLB format'
$tdOut = Join-Path $out 'tower_defense_3d'
New-Item -ItemType Directory -Force (Join-Path $tdOut 'Textures') | Out-Null
'tile.glb','tile-tree.glb','tile-tree-double.glb','tile-rock.glb','tile-crystal.glb','detail-tree.glb','detail-rocks.glb','detail-crystal.glb','selection-a.glb','tower-round-base.glb' | ForEach-Object {
  Copy-Item (Join-Path $tdSource $_) (Join-Path $tdOut $_) -Force
}
Copy-Item (Join-Path $tdSource 'Textures\colormap.png') (Join-Path $tdOut 'Textures\colormap.png') -Force
Write-Host "Assets installed in $out"
