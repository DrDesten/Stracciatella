import fs from "fs"
import path from "path"
import url from "url"
import { guardFiles } from "./guards.js"
import { guardUniforms } from "./parseUniforms.js"
import { compilePropertiesFile, parseProperties } from "./parsePropertiesID.js"
import { FileMapping } from "./filemap.js"
import Changes from "./changes/index.js"
import { parseArgv } from "./argv.js"
import { parseLang } from "./parseProperties.js"

const __dirname = path.resolve( path.dirname( url.fileURLToPath( import.meta.url ) ) )

const root = path.join( __dirname, "../" )
const src = path.join( root, "src" )
const out = path.join( root, "out" )
const shaders = path.join( root, "shaders" )
const changes = new Changes( src )

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Build
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// copy all files
changes.addChangeListener( "**", filepath => {
    const dst = path.join( shaders, filepath )
    fs.mkdirSync( path.dirname( dst ), { recursive: true } )
    fs.cpSync( path.join( src, filepath ), dst )
    console.info( `Copied ${filepath}` )
} )

// generate world folders
changes.addChangeListener( ["*.fsh", "*.vsh", "*.gsh"], filepath => {
    const worlds = [["world-1", "NETHER"], ["world0", "OVERWORLD"], ["world1", "END"]]
    for ( const [world, define] of worlds ) {
        const files = FileMapping[filepath]
        const dir = path.join( shaders, world )
        fs.mkdirSync( dir, { recursive: true } )
        for ( const file of files ) {
            file.addDefine( define )
            fs.writeFileSync( path.join( dir, file.filename ), file.generate() )
            console.info( `Generated ${world}/${file.filename}` )
        }
    }
} )

// guard includes and uniforms
changes.addChangeListener( ["**.fsh", "**.vsh", "**.gsh", "**.glsl", "!core/**"], filepath => {
    const dstpath = path.join( shaders, filepath )
    guardFiles( dstpath )
    guardUniforms( dstpath )
    console.info( `Compiled ${filepath}` )
} )

// compile .properties
changes.addChangeListener( ["block.properties", "item.properties", "entity.properties"], filepath => {
    const dstpath = path.join( shaders, filepath )
    compilePropertiesFile( dstpath )
    console.info( `Compiled ${filepath}` )
} )


/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Command line Options
const options = parseArgv( {
    "feature-list": {},
    persistent: false,
    force: false,
    debug: false,
}, process.argv )

if ( options.command === "feature-list" ) {
    const enUsLang = fs.readFileSync( path.join( src, "lang", "en_us.lang" ), "utf8" )
    const parsedLang = parseLang(enUsLang)

    const parsedLangData = Object.fromEntries(
        parsedLang.map(prop => [prop.key[1], { name: "", comment: "", values: null }])
    )
    for (let { key: [type, id, sub], value } of parsedLang) {
        if (type === "screen" && sub !== "comment") {
            parsedLangData[id].name = value 
            continue
        }
        if (type === "value" && sub !== "comment") {
            parsedLangData[id].values ??= {}
            parsedLangData[id].values[sub] = value 
            continue
        }
        if (type === "option") {
            if (sub === "comment") {
                parsedLangData[id].comment = value 
            } else {
                parsedLangData[id].name = value 
            }
            continue
        }
    }
    
    const shadersProperties = fs.readFileSync( path.join( src, "shaders.properties" ), "utf8" )
    const parsedProperties = parseProperties( shadersProperties ).filter(blk => blk.type === "properties")
    const allScreens = new Map
    for (const block of parsedProperties) {
        for (const p of block) if (p.key[0] === "screen" && p.key.at(-1) !== "columns") {
            const key = p.key[1] ?? ""
            const values = p.value
                .filter(x => x !== "<empty>" && x !== "*")
                .map(x => x.replace(/\W/g, ""))
            allScreens.set(key, values)
        }
    }

    function createScreen( keys ) {
        // Create nested options screen structure
        const screen = {}
        for (const key of keys) {
            screen[key] = parsedLangData[key] ?? { name: key }
            if (allScreens.has(key)) {
                screen[key].children = createScreen(allScreens.get(key))
            }
        }

        // Merge *[RGB] color picker options into one
        const colorPickersOpts = Object.entries(screen).filter(([key]) => /_[RGB]$/.test(key))
        const colorPickers = {}
        for (let [key, value] of colorPickersOpts) {
            value = structuredClone(value)
            value.name = value.name
                .replace(/§\w/g, "")
                .replace(/\s*[RGB]$/, "")
                .replace(/\s*Color$/i, "")
            value.name += " *(RGB Color Picker)*"
            colorPickers[key.slice(0,-2)] ??= { data: value, keys: [] }
            colorPickers[key.slice(0,-2)].keys.push(key)
        }
        for (let [_, { data, keys }] of Object.entries(colorPickers)) {
            if (keys.length !== 3) throw new Error([screen, data, keys])
            screen[keys[0]] = data
            delete screen[keys[1]]
            delete screen[keys[2]]
        }

        return screen
    }
    const screen = createScreen(allScreens.get(""))

    function generateFeatureList( screen, indent = -1 ) {
        let string = ""
        for (const [key, data] of Object.entries(screen)) {
            let { name, comment, values, children } = data
            name = name?.replace(/§\w/g, "")
            comment = comment?.replace(/\.(\s+|$)/g, "  \n").trim()
                .replace(/^(?=.)|(?<=\n)/g, "&emsp;")
                .replace(/§c§n\/!\\§r\s*(.*)(?=  \n|$)/g, "**$1**")
                .replace(/§c(.+?)§r/g, "**$1**")
                .replace(/§n(.+?):?§r/g, "$1:")
                    
            if (children) {
                if (indent === -1) {
                    string += `\n### ${name}\n\n`
                } else {
                    string += " ".repeat(indent * 2) + ` - **${name}**\n`
                }
                string += generateFeatureList(children, indent + 1)
            } else {
                string += " ".repeat(Math.max(indent, 0) * 2) 
                string += ` - ${name}`
                string += values ? ` - *${Object.values(values).map(v => v.replace(/§\w/g, "")).join(", ")}*` : ""
                string += comment ? `  \n${comment}` : ""
                string += "\n"
            }
        }
        return string
    }
    const featureList = generateFeatureList(screen)
    
    const dstpath = path.join(out, "feature-list.md")
    fs.mkdirSync(out, {recursive: true})
    fs.writeFileSync(dstpath, featureList)
    console.info(`Compiled feature list to ${dstpath}`)
    process.exit()
}

if ( options.force ) {
    fs.rmSync( shaders, { recursive: true, force: true } )
    changes.clearCache()
}

if ( options.persistent ) {
    console.info( "Running in persistent mode. Press Ctrl+C to stop.\nWatching for changes..." )

    const debounced = new Set
    const buffer = new Map
    function debouce( filename ) {
        clearTimeout( buffer.get( filename ) )
        buffer.set( filename, setTimeout( () => {
            debounced.add( filename )
            buffer.delete( filename )
            if ( buffer.size === 0 ) trigger()
        }, 1000 ) )
    }
    function trigger() {
        changes.applyPartial( Array.from( debounced ) )
        debounced.clear()
    }

    const watcher = fs.watch( src, { persistent: true, recursive: true }, ( _, filename ) => {
        if ( filename === null ) {
            console.info( "Your system does not support persistent mode. Terminating..." )
            watcher.close()
            process.exit()
        }
        debouce( filename )
    } )
}

// Run Build
await changes.apply()