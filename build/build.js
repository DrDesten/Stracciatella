const fs = require("fs")

class PropertiesFile {
    constructor( source = "" ) {
        this.source = source
        this.fileStructure = []
        this.fileObject = []
        this.parseFile( source )
    }

    parseFile( source ) {

        // Preprocess
        source = parseLinebreaks( source )
        source = parseComments( source )
        source = trimSpaces( source )
        this.source = source

        // Organise and Parse Statements
        let sections = parseScope( source )
        sections     = parseData( sections )
        this.fileStructure = sections

        // Restructure into a target-oriented representaton
        let targetData = parseTargets( sections )
        this.fileObject = targetData

        function parseLinebreaks( txt ) { // Replaces Line break escapes
            return txt.replace(/\s*\\\s*\n/g, "")
        }
        function parseComments( txt ) { // Removes Comments
            return txt.replace(/#(?!if|ifdef|ifndef|elif|else|endif|define|undef).*$/gm, "")
        }
        function trimSpaces( txt ) { // Removes excess spaces and newlines
            return txt.replace(/[ \t]+/g, " ").replace(/\n\s*/g, "\n").replace(/^\s+|\s+$/g, "")
        }
        
        function parseScope( txt ) { // Splits the code up into sections

            let sections = []
            for (const line of txt.split("\n")) {
                let lineType = getLineType(line)
                if ( lineType == sections[ sections.length - 1 ]?.type ) {
                    sections[ sections.length - 1 ].push( line )
                } else {
                    sections.push(Object.assign([ line ], { type: lineType }))
                }
            }

            return sections

            function getLineType( line ) {
                if ( line[0] == "#" ) return "preprocessor"
                else return "data"
            }
        }
        function parseData( sections ) {
            for ( const section of sections ) {
                if ( section.type == "data" ) for ( let i = 0; i < section.length; i++ ) {
                    const statement = section[i]
                    if (/^id/.test(statement)) section[i] = parseId(statement)
                    if (/^data/.test(statement)) section[i] = parseData(statement)
                    if (/^emissive/.test(statement)) section[i] = parseEmissive(statement)
                }
            }
            return sections

            function parseId( line ) {
                let id      = line.split("=")[0]
                let targets = line.split("=")[1].split(" ")
                return {
                    data: "id",
                    value: +id.replace("id.", ""), // keep number
                    targets: targets
                }
            }
            function parseData( line ) {
                let data    = line.split("=")[0]
                let targets = line.split("=")[1].split(" ")
                return {
                    data: "data",
                    value: +data.replace("data.", ""), // keep number
                    targets: targets
                }
            }
            function parseEmissive( line ) {
                let emissive = line.split("=")[0]
                let targets  = line.split("=")[1].split(" ")
                return {
                    data: "emissive",
                    value: true,
                    targets: targets
                }
            }
        }

        function parseTargets( sections ) {
            let targetSections = []
            for ( const section of sections ) {
                if ( section.type == "preprocessor" ) {
                    targetSections.push(Object.assign([ ...section ], { type: section.type }))
                }
                if ( section.type == "data" ) {
                    const targets = {}
                    for ( const statement of section ) {
                        for ( const target of statement.targets ) {
                            if ( targets[ target ] == undefined ) targets[ target ] = {}
                            const t = targets[ target ]
                            t[ statement.data ] = statement.value
                        }
                    }
                    targetSections.push(targets)
                }
            }
            return targetSections
        }

    }

}


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

new PropertiesFile(blockProperties)

let compiled = processPropertiesFile(blockProperties)

//console.log(compiled)

fs.writeFileSync(__dirname + "/block.properties.out", compiled)
