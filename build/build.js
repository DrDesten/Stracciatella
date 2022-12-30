const fs = require("fs")
const { guardFiles } = require("./generateIncludeGuards.js")
const { guardUniforms } = require("./parseUniforms.js")
const { PropertiesFile, PropertiesParser, PropertiesCompiler, loadProperties, compileProperties } = require("./parseProperties.js")

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Copy Directory Over
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

fs.cpSync(`${__dirname}/../src`, `${__dirname}/../shaders`, { force: true, recursive: true })
const dir = `${__dirname}/../shaders`

/** @param {string} dir @returns {string[]} */
function gatherFiles( dir, fileList = [] ) {
    // Get all Files and Directories in the current folder
    let files = fs.readdirSync( dir )
        .map( path => `${dir}/${path}` )
        .filter( path => fs.lstatSync(path).isDirectory() || fs.lstatSync(path).isFile() )
    // Recursively add files in subdirectories ( && is used for short-circuiting )
    files.forEach( path => fs.lstatSync(path).isDirectory() && gatherFiles(path, fileList) )
    // Filter out Directories, as everything should have resolved now
    files = files.filter( path => fs.lstatSync(path).isFile() )
    // Add all found files to the referenced array
    fileList.push( ...files )
    return fileList
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compile Files
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const files = gatherFiles(dir)

for ( const path of files ) {

    const fext  = path => path.match(/.*\.(\w+)$/)?.[1]
    const fname = path => path.match(/.*\/([\w\.]*)\.\w+$/)?.[1]
    const ffull = path => `${fname(path)}.${fext(path)}`

    const indir = (path, dir) => typeof dir == "string" ? path.includes(dir) : dir.test(path)
    
    switch ( fext(path) ) {
        case "properties":
            if ( ["block","item","entity"].includes(fname(path))) {
                new PropertiesCompiler(fs.readFileSync(path, {encoding: "utf8"})).parseProperties().orientTarget()
                const propertiesFile = loadProperties( path )
                //console.log(propertiesFile.fileObject)
                compileProperties( propertiesFile )
            }
            break
        case "fsh":
        case "vsh":
        case "glsl":
            if (!indir(path, /world-?\d/)) guardFiles(path)
            guardUniforms(path)
            break




    }
}
