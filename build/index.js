import fs from "fs"
import path from "path"
import url from "url"
import { guardFiles } from "./guards.js"
import { guardUniforms } from "./parseUniforms.js"
import { PropertiesFile, PropertiesParser, PropertiesCompiler, loadProperties, compileProperties } from "./parseProperties.js"
import { FileMapping } from "./filemap.js"
import Changes from "./changes/index.js"

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copy Directory Over
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const src = path.join( __dirname, "../src" )
const shaders = path.join( __dirname, "../shaders" )
const changes = new Changes( src )

// Force Rebuild
if ( process.argv[2] === "-f" || process.argv[2] === "--force" ) {
    fs.rmSync( shaders, { recursive: true, force: true } )
    changes.clearCache()
}

// copy all files
changes.addChangeListener( "*", filepath => {
    const dst = path.join( shaders, filepath )
    fs.mkdirSync( path.dirname( dst ), { recursive: true } )
    fs.cpSync( path.join( src, filepath ), dst )
    console.info( `Copied ${filepath}` )
} )

// generate world folders
changes.addChangeListener( ["/*.fsh", "/*.vsh", "/*.gsh"], filepath => {
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

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compile Files
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

changes.addChangeListener( ["*.fsh", "*.vsh", "*.gsh", "*.glsl"], filepath => {
    const dstpath = path.join( shaders, filepath )
    guardFiles( dstpath )
    guardUniforms( dstpath )
    console.log( `Compiled ${filepath}` )
} )
changes.addChangeListener( ["block.properties", "item.properties", "entity.properties"], filepath => {
    const dstpath = path.join( shaders, filepath )
    const propertiesFile = loadProperties( dstpath )
    compileProperties( propertiesFile )
    console.log( `Compiled ${filepath}` )
} )

await changes.apply()