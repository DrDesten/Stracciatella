import fs from "fs"
import path from "path"
import url from "url"
import { guardFiles } from "./generateIncludeGuards.js"
import { guardUniforms } from "./parseUniforms.js"
import { PropertiesFile, PropertiesParser, PropertiesCompiler, loadProperties, compileProperties } from "./parseProperties.js"
import { FileMapping } from "./filemap.js"

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copy Directory Over
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const src = `${__dirname}/../src`
const shaders = `${__dirname}/../shaders`

if ( fs.existsSync( shaders ) ) {
    fs.rmSync( shaders, { recursive: true } )
    console.info( "Deleted `shaders`" )
}

fs.mkdirSync( shaders )
fs.cpSync( path.join( src, "core" ), path.join( shaders, "core" ), { recursive: true } )
fs.cpSync( path.join( src, "lang" ), path.join( shaders, "lang" ), { recursive: true } )
fs.cpSync( path.join( src, "lib" ), path.join( shaders, "lib" ), { recursive: true } )
fs.cpSync( path.join( src, "lut" ), path.join( shaders, "lut" ), { recursive: true } )
console.info( "Copied subfolders into `shaders`" )

// Get shader files
const shaderFiles = fs.readdirSync( src ).filter( file => fs.statSync( path.join( src, file ) ).isFile() )
const shaderFileSet = new Set( shaderFiles )
for ( const file of shaderFiles ) {
    fs.cpSync( path.join( src, file ), path.join( shaders, file ) )
}
console.info( "Copied shader files into `shaders`" )

// Generate world folders
const worlds = {
    "world-1": [],
    "world0": [],
    "world1": [],
}
for ( const file of shaderFiles ) {
    for ( const world in worlds ) {
        const files = FileMapping[file]

        for ( const file of files ) {
            file.addDefine( {
                "world-1": "NETHER",
                "world0": "OVERWORLD",
                "world1": "END",
            }[world] )
        }

        worlds[world].push( ...files )
    }
}

// Save World Folders
for ( const [world, files] of Object.entries( worlds ) ) {
    const worldDir = path.join( shaders, world )
    fs.mkdirSync( worldDir )

    for ( const file of files ) {
        fs.writeFileSync( path.join( worldDir, file.filename ), file.generate() )
    }
}
console.info( "Generated world folders" )

const dir = shaders

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

const files = gatherFiles( dir )

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
