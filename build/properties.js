const properties = `# Water
id.1=minecraft:water
# Lava
emissive.data.63.id.2=minecraft:lava minecraft:flowing_lava

# Wavy stuff (1 block tall)
id.10=minecraft:grass minecraft:fern minecraft:seagrass minecraft:crimson_roots minecraft:warped_roots minecraft:nether_sprouts        minecraft:dandelion minecraft:poppy minecraft:blue_orchid minecraft:allium minecraft:azure_bluet minecraft:red_tulip minecraft:orange_tulip minecraft:white_tulip minecraft:pink_tulip minecraft:oxeye_daisy minecraft:cornflower minecraft:lily_of_the_valley minecraft:wither_rose minecraft:sweet_berry_bush minecraft:tube_coral minecraft:brain_coral minecraft:bubble_coral minecraft:fire_coral minecraft:horn_coral minecraft:dead_tube_coral minecraft:dead_brain_coral minecraft:dead_bubble_coral minecraft:dead_fire_coral minecraft:dead_horn_coral minecraft:tube_coral_fan minecraft:brain_coral_fan minecraft:bubble_coral_fan minecraft:fire_coral_fan minecraft:horn_coral_fan minecraft:dead_tube_coral_fan minecraft:dead_brain_coral_fan minecraft:dead_bubble_coral_fan minecraft:dead_fire_coral_fan minecraft:dead_horn_coral_fan               minecraft:wheat minecraft:carrots minecraft:potatoes minecraft:beetroots        oak_sapling minecraft:spruce_sapling minecraft:birch_sapling minecraft:jungle_sapling minecraft:acacia_sapling minecraft:dark_oak_sapling minecraft:dead_bush minecraft:nether_wart  minecraft:big_dripleaf
# Wavy stuff (2 Blocks Tall, lower section)
id.11=minecraft:sunflower:half=lower minecraft:lilac:half=lower minecraft:tall_grass:half=lower minecraft:large_fern:half=lower minecraft:rose_bush:half=lower minecraft:peony:half=lower minecraft:tall_seagrass:half=lower minecraft:small_dripleaf:half=lower
# Wavy stuff (2 Blocks Tall, upper section)
id.12=minecraft:sunflower:half=upper minecraft:lilac:half=upper minecraft:tall_grass:half=upper minecraft:large_fern:half=upper minecraft:rose_bush:half=upper minecraft:peony:half=upper minecraft:tall_seagrass:half=upper minecraft:kelp minecraft:kelp_plant minecraft:cave_vines_plant minecraft:cave_vines minecraft:small_dripleaf:half=upper
# Leaves
id.13=minecraft:oak_leaves minecraft:spruce_leaves minecraft:birch_leaves minecraft:jungle_leaves minecraft:acacia_leaves minecraft:dark_oak_leaves minecraft:azalea_leaves minecraft:flowering_azalea_leaves minecraft:mangrove_leaves
# Hanging Lanterns
emissive.data.63.id.14=minecraft:lantern:hanging=true minecraft:soul_lantern:hanging=true

# Wavy Stuff (Waves like water)
id.15=minecraft:lily_pad

# Fire
emissive.data.63.id.16=minecraft:fire minecraft:soul_fire  

# Emissives ------------------------------------------------------------------
# missing stuff: cave vines with berries, redstone, (some) sculk blocks
# White Color
emissive.data.63.id.20=minecraft:sea_lantern minecraft:end_rod minecraft:beacon
emissive.data.63.id.20=minecraft:sea_pickle
# Orange Color
emissive.data.63.id.21=minecraft:glowstone minecraft:shroomlight minecraft:jack_o_lantern minecraft:redstone_lamp:lit=true minecraft:lantern furnace:lit=true minecraft:blast_furnace:lit=true minecraft:smoker:lit=true minecraft:lava_cauldron minecraft:campfire:lit=true minecraft:torch minecraft:wall_torch minecraft:magma_block
# Red Color
emissive.data.63.id.22=minecraft:redstone_torch:lit=true minecraft:redstone_wall_torch:lit=true
emissive.data.0.id.22 =minecraft:redstone_wire:power=1 minecraft:redstone_wire:power=2 minecraft:redstone_wire:power=3 minecraft:redstone_wire:power=4 minecraft:redstone_wire:power=5 minecraft:redstone_wire:power=6 minecraft:redstone_wire:power=7 minecraft:redstone_wire:power=8 minecraft:redstone_wire:power=9 minecraft:redstone_wire:power=10 minecraft:redstone_wire:power=11 minecraft:redstone_wire:power=12 minecraft:redstone_wire:power=13 minecraft:redstone_wire:power=14 minecraft:redstone_wire:power=15
# Blue Color
emissive.data.63.id.23=minecraft:soul_lantern soul_campfire:lit=true minecraft:soul_torch minecraft:soul_wall_torch 
emissive.data.63.id.23=minecraft:sculk_sensor:sculk_sensor_phase=active minecraft:sculk_catalyst
emissive.data.0.id.23 =minecraft:sculk_sensor:sculk_sensor_phase=inactive minecraft:sculk minecraft:sculk_vein
# Purple Color
emissive.data.63.id.24=minecraft:budding_amethyst minecraft:crying_obsidian minecraft:small_amethyst_bud minecraft:medium_amethyst_bud minecraft:large_amethyst_bud minecraft:amethyst_cluster 
emissive.data.0.id.24 =minecraft:amethyst
# Any Color
emissive.data.63.id.25=minecraft:glow_lichen
# Any Color (Low HDR)
emissive.data.63.id.26=minecraft:pearlescent_froglight minecraft:ochre_froglight minecraft:verdant_froglight
# Candles
emissive.data.63.id.27=minecraft:candle:lit=true minecraft:white_candle:lit=true minecraft:orange_candle:lit=true minecraft:magenta_candle:lit=true minecraft:light_blue_candle:lit=true minecraft:yellow_candle:lit=true minecraft:lime_candle:lit=true minecraft:pink_candle:lit=true minecraft:gray_candle:lit=true minecraft:light_gray_candle:lit=true minecraft:cyan_candle:lit=true minecraft:purple_candle:lit=true minecraft:blue_candle:lit=true minecraft:brown_candle:lit=true minecraft:green_candle:lit=true minecraft:red_candle:lit=true minecraft:black_candle:lit=true


# ORES #############################################################################################################################
# Diamond
id.40=minecraft:diamond_ore minecraft:deepslate_diamond_ore
# Ancient Debris
id.41=minecraft:ancient_debris
# Iron
id.42=minecraft:iron_ore minecraft:deepslate_iron_ore
# Gold
id.43=minecraft:gold_ore minecraft:deepslate_gold_ore
# Copper
id.44=minecraft:copper_ore minecraft:deepslate_copper_ore
# Redstone
id.45=minecraft:redstone_ore minecraft:deepslate_redstone_ore
# Lapis
id.46=minecraft:lapis_ore minecraft:deepslate_lapis_ore
# Emerald
id.47=minecraft:emerald_ore minecraft:deepslate_emerald_ore
# Coal
id.48=minecraft:coal_ore minecraft:deepslate_coal_ore
# Nether Quarz
id.49=minecraft:nether_quartz_ore
# Nether Gold
id.50=minecraft:nether_gold_ore`

/** @param {string} string */
function parsePrimitive( string ) {
    if ( string === "NaN" ) return NaN
    if ( !isNaN( +string ) ) return +string

    if ( string === "true" ) return true
    if ( string === "false" ) return false

    if ( string === "undefined" ) return undefined
    if ( string === "null" ) return null

    return string
}

function parseProperties( propertiesFile = "" ) {
    propertiesFile = propertiesFile.replace( /#.*/g, "" ) // Remove Comments
    propertiesFile = propertiesFile.replace( /[ \t]*\\[ \t]*\n[ \t]*/g, " " ).trim() // Handle Newline Escapes

    let propertiesLines = propertiesFile.split( /\s*\n\s*/g ) // Split into Array
    let propertiesArr = []
    for ( const line of propertiesLines ) {
        let keys = line.split( /\s*=\s*/g, 2 )[0]
            .split( /\s*\.\s*/g )
            .map( parsePrimitive )
        let values = line.split( /\s*=\s*/g, 2 )[1]
            .split( /\s+/g )
            .map( parsePrimitive )
        propertiesArr.push( { keys, values } )
    }

    return propertiesArr
}

function parseProperties( propertiesFile = "", keymap = {} ) {
    propertiesFile = propertiesFile.replace( /#.*/g, "" ) // Remove Comments
    propertiesFile = propertiesFile.replace( /[ \t]*\\[ \t]*\n[ \t]*/g, " " ).trim() // Handle Newline Escapes

    let propertiesLines = propertiesFile.split( /\s*\n\s*/g ) // Split into Array
    let propertiesArr = []
    for ( const line of propertiesLines ) {
        let keys = line.split( /\s*=\s*/g, 2 )[0]
            .split( /\s*\.\s*/g )
            .map( parsePrimitive )
        let values = line.split( /\s*=\s*/g, 2 )[1]
            .split( /\s+/g )
            .map( parsePrimitive )

        for (let i = 0; i < keys.length; i++) {
            let key = keys[i]
            if (keymap[key] === undefined) continue

            let mapping = keymap[key]
            
        }
    }

    return propertiesArr
}

const KEYS = {
    id: { arguments: 1, default: [0], types: ["number"] },
    emissive: { arguments: 1, default: [true], types: ["boolean"] },
    data: { arguments: 1, default: [0], types: ["number"] },
}

console.log( parseProperties( properties ) )