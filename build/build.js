const fs = require("fs")
const { PropertiesFile, loadProperties, compileProperties } = require("./parseProperties.js")

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
// Compile Properties Files
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const blockProperties = loadProperties("block.properties");
compileProperties( blockProperties )


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Compile Files
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

const files = gatherFiles(dir)


