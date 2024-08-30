import fs from "fs"
import path from "path"
import url from "url"
import { guardFiles } from "./guards.js"
import { guardUniforms } from "./parseUniforms.js"
import { compilePropertiesFile, parseProperties } from "./parseProperties.js"
import { FileMapping } from "./filemap.js"
import Changes from "./changes/index.js"
import { parseArgv } from "./argv.js"

const __dirname = path.resolve( path.dirname( url.fileURLToPath( import.meta.url ) ) )
const __root = path.join( __dirname, "../" )

const src = path.join( __root, "src" )
const shaders = path.join( __root, "shaders" )
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
    readme: {},
    persistent: false,
    force: false,
    debug: false,
}, process.argv )

if ( options.command === "readme" ) {
    const shadersProperties = fs.readFileSync( path.join( src, "shaders.properties" ), "utf8" )
    console.log( parseProperties( shadersProperties ) )
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