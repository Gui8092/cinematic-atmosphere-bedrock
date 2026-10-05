<#
    biome-map.ps1 — Fonte unica de verdade do mapeamento bioma -> configuracao.

    Nao contem logica de escrita; e importado por generate-biomes.ps1 e validate.ps1.

    Referencias de biomas: tag estavel v1.26.50.4 do repositorio oficial
    https://github.com/Mojang/bedrock-samples/tree/v1.26.50.4/resource_pack/biomes
    (89 arquivos *.client_biome.json — confere com o caminho resource_pack/biomes/).

    Namespace do pack: "cba". O namespace "minecraft" e reservado aos packs vanilla.
#>

# --- Identificadores declarados pelo pack ------------------------------------
$CbaIdentifiers = [ordered]@{
    Lighting      = @('cba:lighting_overworld', 'cba:lighting_forest', 'cba:lighting_cold', 'cba:lighting_mountain', 'cba:lighting_hot', 'cba:lighting_ocean', 'cba:lighting_swamp', 'cba:lighting_cave', 'cba:lighting_nether', 'cba:lighting_end')
    Atmospherics  = @('cba:atmos_overworld', 'cba:atmos_cold', 'cba:atmos_hot', 'cba:atmos_nether', 'cba:atmos_end')
    ColorGrading  = @('cba:cg_overworld', 'cba:cg_cold', 'cba:cg_hot', 'cba:cg_swamp', 'cba:cg_cave', 'cba:cg_nether', 'cba:cg_end')
    Water         = @('cba:water_fresh', 'cba:water_ocean', 'cba:water_deep', 'cba:water_warm', 'cba:water_frozen', 'cba:water_swamp')
    Fog           = @('cba:fog_default', 'cba:fog_forest', 'cba:fog_cold', 'cba:fog_mountain', 'cba:fog_hot', 'cba:fog_ocean', 'cba:fog_swamp', 'cba:fog_cave', 'cba:fog_nether', 'cba:fog_end')
    Cubemap       = @('cba:cubemap_overworld')
}

# --- Familias ---------------------------------------------------------------
# Cubemap: $null = nao atribuido (so Overworld e valido; Nether/End usam cubemap proprio).
$CbaFamilies = [ordered]@{
    'temperate' = @{
        Label = 'T01 Temperado'; Lighting = 'cba:lighting_overworld'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_fresh'; Fog = 'cba:fog_default'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('plains', 'sunflower_plains', 'meadow', 'river', 'birch_forest', 'birch_forest_hills',
                   'birch_forest_hills_mutated', 'birch_forest_mutated', 'forest', 'forest_hills', 'flower_forest',
                   'cherry_grove', 'mushroom_island', 'mushroom_island_shore')
    }
    'forest' = @{
        Label = 'T02 Floresta densa'; Lighting = 'cba:lighting_forest'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_fresh'; Fog = 'cba:fog_forest'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('roofed_forest', 'roofed_forest_mutated', 'jungle', 'jungle_edge', 'jungle_edge_mutated',
                   'jungle_hills', 'jungle_mutated', 'bamboo_jungle', 'bamboo_jungle_hills', 'mega_taiga',
                   'mega_taiga_hills', 'redwood_taiga_mutated', 'redwood_taiga_hills_mutated', 'grove',
                   'dappled_forest')
    }
    'cold' = @{
        Label = 'T03 Taiga e neve'; Lighting = 'cba:lighting_cold'; Atmospherics = 'cba:atmos_cold'
        ColorGrading = 'cba:cg_cold'; Water = 'cba:water_fresh'; Fog = 'cba:fog_cold'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('taiga', 'taiga_hills', 'taiga_mutated', 'cold_taiga', 'cold_taiga_hills', 'cold_taiga_mutated',
                   'ice_plains', 'ice_plains_spikes', 'ice_mountains', 'frozen_river', 'snowy_slopes')
    }
    'mountain' = @{
        Label = 'T04 Montanhas e picos'; Lighting = 'cba:lighting_mountain'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_fresh'; Fog = 'cba:fog_mountain'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('extreme_hills', 'extreme_hills_edge', 'extreme_hills_mutated', 'extreme_hills_plus_trees',
                   'extreme_hills_plus_trees_mutated', 'jagged_peaks', 'stony_peaks', 'frozen_peaks')
    }
    'hot' = @{
        Label = 'T05 Deserto e Badlands'; Lighting = 'cba:lighting_hot'; Atmospherics = 'cba:atmos_hot'
        ColorGrading = 'cba:cg_hot'; Water = 'cba:water_fresh'; Fog = 'cba:fog_hot'; Cubemap = $null
        Biomes = @('desert', 'desert_hills', 'desert_mutated', 'mesa', 'mesa_bryce', 'mesa_plateau',
                   'mesa_plateau_mutated', 'mesa_plateau_stone', 'mesa_plateau_stone_mutated')
    }
    'savanna' = @{
        Label = 'T06 Savana'; Lighting = 'cba:lighting_hot'; Atmospherics = 'cba:atmos_hot'
        ColorGrading = 'cba:cg_hot'; Water = 'cba:water_fresh'; Fog = 'cba:fog_hot'; Cubemap = $null
        Biomes = @('savanna', 'savanna_mutated', 'savanna_plateau', 'savanna_plateau_mutated')
    }
    'beach' = @{
        Label = 'T09 Praia e rio'; Lighting = 'cba:lighting_overworld'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_fresh'; Fog = 'cba:fog_default'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('beach', 'stone_beach', 'cold_beach')
    }
    'swamp' = @{
        Label = 'T10 Pantano'; Lighting = 'cba:lighting_swamp'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_swamp'; Water = 'cba:water_swamp'; Fog = 'cba:fog_swamp'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('swampland', 'swampland_mutated', 'mangrove_swamp')
    }
    'cave' = @{
        Label = 'T11 Cavernas'; Lighting = 'cba:lighting_cave'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_cave'; Water = 'cba:water_fresh'; Fog = 'cba:fog_cave'; Cubemap = $null
        Biomes = @('dripstone_caves', 'lush_caves', 'deep_dark', 'sulfur_caves')
    }
    'pale_garden' = @{
        Label = 'T14 Pale Garden'; Lighting = 'cba:lighting_cold'; Atmospherics = 'cba:atmos_cold'
        ColorGrading = 'cba:cg_cave'; Water = 'cba:water_swamp'; Fog = 'cba:fog_cold'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('pale_garden')
    }
    'ocean_plain' = @{
        Label = 'T7a Oceano raso'; Lighting = 'cba:lighting_ocean'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_ocean'; Fog = 'cba:fog_ocean'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('ocean', 'cold_ocean')
    }
    'ocean_warm' = @{
        Label = 'T7b Oceano quente'; Lighting = 'cba:lighting_ocean'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_warm'; Fog = 'cba:fog_ocean'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('lukewarm_ocean', 'warm_ocean', 'deep_warm_ocean', 'deep_lukewarm_ocean')
    }
    'ocean_frozen' = @{
        Label = 'T7c Oceano gelado'; Lighting = 'cba:lighting_ocean'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_frozen'; Fog = 'cba:fog_ocean'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('frozen_ocean', 'deep_frozen_ocean', 'legacy_frozen_ocean')
    }
    'ocean_deep' = @{
        Label = 'T8 Oceano profundo'; Lighting = 'cba:lighting_ocean'; Atmospherics = 'cba:atmos_overworld'
        ColorGrading = 'cba:cg_overworld'; Water = 'cba:water_deep'; Fog = 'cba:fog_ocean'; Cubemap = 'cba:cubemap_overworld'
        Biomes = @('deep_ocean', 'deep_cold_ocean')
    }
    'nether' = @{
        Label = 'T12 Nether'; Lighting = 'cba:lighting_nether'; Atmospherics = 'cba:atmos_nether'
        ColorGrading = 'cba:cg_nether'; Water = 'cba:water_fresh'; Fog = 'cba:fog_nether'; Cubemap = $null
        Biomes = @('hell', 'crimson_forest', 'warped_forest', 'basalt_deltas', 'soulsand_valley')
    }
    'end' = @{
        Label = 'T13 End'; Lighting = 'cba:lighting_end'; Atmospherics = 'cba:atmos_end'
        ColorGrading = 'cba:cg_end'; Water = 'cba:water_fresh'; Fog = 'cba:fog_end'; Cubemap = $null
        Biomes = @('the_end')
    }
}

# --- Componentes Vibrant Visuals substituidos -------------------------------
$CbaVvComponents = @(
    'minecraft:atmosphere_identifier',
    'minecraft:color_grading_identifier',
    'minecraft:lighting_identifier',
    'minecraft:water_identifier',
    'minecraft:cubemap_identifier',
    'minecraft:fog_appearance'
)

# Componentes que NAO podem ser removidos dos arquivos vanilla ao reescrever:
# sem eles, sobrescrever um client_biome apagaria som/musica/cores do bioma.
$CbaPreservedComponents = @(
    'minecraft:ambient_sounds',
    'minecraft:biome_music',
    'minecraft:grass_appearance',
    'minecraft:foliage_appearance',
    'minecraft:dry_foliage_color',
    'minecraft:sky_color',
    'minecraft:water_appearance',
    'minecraft:precipitation'
)

# --- Tag vanilla de referencia ----------------------------------------------
$CbaVanillaRef = @{
    Repo      = 'Mojang/bedrock-samples'
    Tag       = 'v1.26.50.4'
    BiomesDir = 'resource_pack/biomes'
}

# --- Helper: indice bioma -> familia ----------------------------------------
function Get-CbaBiomeIndex {
    $map = [ordered]@{}
    foreach ($key in $CbaFamilies.Keys) {
        foreach ($b in $CbaFamilies[$key].Biomes) {
            if ($map.Contains($b)) { throw "Bioma duplicado no mapa: '$b' ($key e $($map[$b]))" }
            $map[$b] = $key
        }
    }
    return $map
}