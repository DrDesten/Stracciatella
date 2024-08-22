import fs from "fs"
import path from "path"

const fext = p => path.basename( p ).match( /(?<=\.)[^\.]*$/ )[0]
const fname = p => path.basename( p ).match( /^[^\.]*/ )[0]

export function guardFiles( path ) {
    let content = fs.readFileSync( path, { encoding: "utf-8" } )
    const define = `INCLUDE_${fname( path )}_${fext( path )}`.toUpperCase()
    content = `#if ! defined ${define}\n#define ${define}\n\n${content}\n\n#endif`
    fs.writeFileSync( path, content )
}