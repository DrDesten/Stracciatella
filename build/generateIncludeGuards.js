const fs = require("fs")

const fext  = path => path.match(/.*\.(\w+)$/)?.[1]
const fname = path => path.match(/.*\/([\w\.]*)\.\w+$/)?.[1]
const ffull = path => `${fname(path)}.${fext(path)}`

function guardFiles( path ) {
    let   content = fs.readFileSync( path, { encoding: "utf-8" })
    const define  = `INCLUDE_${fname(path)}_${fext(path)}`.toUpperCase()
    content = `#if ! defined ${define}\n#define ${define}\n\n${content}\n\n#endif`
    fs.writeFileSync( path, content )
}


module.exports = {
    guardFiles
}