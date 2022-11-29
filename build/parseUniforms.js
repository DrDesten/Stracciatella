const fs = require("fs")

function guardUniforms( path ) {
    let content = fs.readFileSync( path, { encoding: "utf-8" })
    content = content.replace(/\s*uniform\s+(\w+)\s+(\w+)\s*;\s*/g, `\n#ifndef INCLUDE_UNIFORM_$1_$2\n#define INCLUDE_UNIFORM_$1_$2\nuniform $1 $2;\n#endif\n`)
    fs.writeFileSync( path, content )
}


module.exports = {
    guardUniforms
}