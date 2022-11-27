const fs = require("fs")

/** @param {string} propertiesFile */
function preprocess( propertiesFile ) {

    propertiesFile = propertiesFile
        .replace(/\\\s*\n/, " ") // Handle Newline escapes
        .split("\n") // Split into lines
        .map( line =>
            line.split(/#(?!if|elif|else|endif)/)[0] // Remove all comments, except preprocessor directives
            .trim().replace(/\s+/g, " ") // Remove duplicate Whitespace
        )
        .filter( x => x.trim() ) // Remove empty lines
        .join("\n") // Join back to string

    return propertiesFile

}

/** @param {string} propertiesFile */
function parse( propertiesFile ) { // Splits the file into blocks and parses those for id's, emissive flag and data

    return propertiesFile
        .split(/(?=#)|(?<=#.*\n)/)
        .map( block => { 
            if (block[0] == "#") {
                return { type: "preprocessor", data: block.trim() }
            } else {
                let lines = block.split("\n")
                let elements = []

                for (const line of lines) {
                    const isId = /^id\.(\d+)\s*=\s*/
                    const isEmissive = /^emissive\s*=\s*/
                    const isData = /^data\.(\d+)\s*=\s*/

                    if (isId.test(line)) {
                        const lineId       = isId.exec(line)[1]
                        const lineElements = line.replace(isId,"").split(" ")

                        for (const element of lineElements) {
                            const index = elements.findIndex( ele => ele.name == element )
                            if (index >= 0) {
                                elements[index].id = lineId
                            } else {
                                elements.push({
                                    name: element,
                                    id: lineId
                                })
                            }
                        }
                    }
                    if (isEmissive.test(line)) {
                        const lineElements = line.replace(isEmissive,"").split(" ")

                        for (const element of lineElements) {
                            const index = elements.findIndex( ele => ele.name == element )
                            if (index >= 0) {
                                elements[index].emissive = true
                            } else {
                                elements.push({
                                    name: element,
                                    emissive: true
                                })
                            }
                        }
                    }
                    if (isData.test(line)) {
                        const lineData     = isData.exec(line)[1]
                        const lineElements = line.replace(isData,"").split(" ")

                        for (const element of lineElements) {
                            const index = elements.findIndex( ele => ele.name == element )
                            if (index >= 0) {
                                elements[index].data = lineData
                            } else {
                                elements.push({
                                    name: element,
                                    data: lineData
                                })
                            }
                        }
                    }

                }

                return {
                    type: "data",
                    elements: elements,
                }
            }
        } )

}

function computePacked( propertiesObject ) {
    for (const block of propertiesObject) {
        if (block.type == "data") {
            for (const ele of block.elements) {
                const id = ~~ele.id
                const emissive = ~~ele.emissive
                const data = ~~ele.data

                ele.packed = (id << 8) + (emissive << 7) + data
            }
        }
    }
}

function compile( propertiesObject ) {
    // Compress object
    for (const block of propertiesObject) {
        if (block.type == "data") {
            block.packedIds = {}

            for (const ele of block.elements) {
                const packed = ele.packed
                if (block.packedIds[packed] == undefined) block.packedIds[packed] = [ ele.name ]
                else block.packedIds[packed].push( ele.name )
            }
        }
    } 

    // Build new properties file
    let string = ""
    for (const block of propertiesObject) {
        if (block.type == "preprocessor") {
            string += block.data + "\n"
        }
        if (block.type == "data") {
            for (const id in block.packedIds) {
                string += `block.${id}=${block.packedIds[id].join(" ")}\n`
            }
        }
    }

    return string
}

function processPropertiesFile( string ) {
    string = preprocess(string)
    string = parse(string)
    computePacked(string)
    string = compile(string)
    return string
}

const blockProperties = fs.readFileSync(__dirname + "/block.properties", {encoding: "utf8"})

let compiled = processPropertiesFile(blockProperties)

console.log(compiled)

fs.writeFileSync(__dirname + "/block.properties.out", compiled)
