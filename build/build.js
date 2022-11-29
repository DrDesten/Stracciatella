const fs = require("fs")
const { PropertiesFile, loadProperties, compileProperties } = require("./parseProperties.js")
const { guardUniforms } = require("./parseUniforms.js")

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
    
    switch ( fext(path) ) {
        case "properties":
            if ( ["block","item","entity"].includes(fname(path))) {
                const propertiesFile = loadProperties( path )
                compileProperties( propertiesFile )
            }
            break
        case "fsh":
        case "vsh":
        case "glsl":
            guardUniforms(path)
            break




    }
}
