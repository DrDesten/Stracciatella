import fs from "fs"
import path from "path"
import url from "url"
import { guardFiles } from "./generateIncludeGuards.js"
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

await changes.apply()

/** @param {string} dir @returns {string[]} */
function gatherFiles( dir, fileList = [] ) {
    // Get all Files and Directories in the current folder
    let files = fs.readdirSync( dir )
        .map( path => `${dir}/${path}` )
        .filter( path => fs.lstatSync( path ).isDirectory() || fs.lstatSync( path ).isFile() )
    // Recursively add files in subdirectories ( && is used for short-circuiting )
    files.forEach( path => fs.lstatSync( path ).isDirectory() && gatherFiles( path, fileList ) )
    // Filter out Directories, as everything should have resolved now
    files = files.filter( path => fs.lstatSync( path ).isFile() )
    // Add all found files to the referenced array
    fileList.push( ...files )
    return fileList
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compile Files
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const files = gatherFiles( shaders )

for ( const filepath of files ) {

    const fext = path => path.match( /.*\.(\w+)$/ )?.[1]
    const fname = path => path.match( /.*\/([\w\.]*)\.\w+$/ )?.[1]
    const ffull = path => `${fname( path )}.${fext( path )}`

    const indir = ( path, dir ) => typeof dir == "string" ? path.includes( dir ) : dir.test( path )

    if ( indir( filepath, "shaders/core" ) )
        continue

    switch ( path.extname( filepath ) ) {
        case ".properties":
            if ( ["block", "item", "entity"].includes( path.basename( filepath, ".properties" ) ) ) {
                //new PropertiesCompiler(fs.readFileSync(path, {encoding: "utf8"})).parseProperties().orientTarget()
                const propertiesFile = loadProperties( filepath )
                //console.log(propertiesFile.fileObject)
                compileProperties( propertiesFile )
            }
            break
        case ".fsh":
        case ".vsh":
        case ".glsl":
            if ( !indir( filepath, /world-?\d/ ) ) guardFiles( filepath )
            guardUniforms( filepath )
            break
    }
}
