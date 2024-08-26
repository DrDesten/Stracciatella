import fs from "fs"
import path from "path"
import crypto from "crypto"

export function guardFiles( filepath ) {
    let content = fs.readFileSync( filepath, { encoding: "utf-8" } )
    const hash = crypto.createHash( "sha1" ).update( filepath ).digest( "hex" ).slice( 0, 4 )
    const define = `INCLUDE_${path.basename( filepath ).replace( /\W+/g, "_" )}_${hash}`.toUpperCase()
    content = `#if ! defined ${define}\n#define ${define}\n\n${content}\n\n#endif`
    fs.writeFileSync( filepath, content )
}