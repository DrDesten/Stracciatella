const fs = require("fs")

class PropertiesFile {
    constructor( path, source, statementPrefix ) {
        this.path = path
        this.source = source
        this.prefix = statementPrefix
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
        this.fileStructure = sections

        // Restructure into a target-oriented representaton
        let targetData = parseData( sections )
        this.fileObject = targetData

        function parseLinebreaks( txt ) { // Replaces Line break escapes
            return txt.replace(/\s*\\\s*\n/g, "")
        }
        function parseComments( txt ) { // Removes Comments
            return txt.replace(/#(?!if|ifdef|ifndef|elif|else|endif|define|undef).*$/gm, "")
        }
        function trimSpaces( txt ) { // Removes excess spaces and newlines
            return txt.replace(/[ \t]+/g, " ").replace(/\s*\n\s*/g, "\n").trim()
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
            let targetSections = []
            for ( const section of sections ) {
                if ( section.type == "data" ) {
                    let targetSection = { type: "data" }
                    for ( let i = 0; i < section.length; i++ ) {
                        const tags = {
                            id: undefined, data: undefined, emissive: undefined
                        }
                        const tagRegex = {
                            tag: /^\.?(\w+)\s*/,
                            id: /^\.?id\.(\d+)\s*/,
                            data: /^\.?data\.(\d+)\s*/,
                            emissive: /^\.?emissive\s*/,
                        }
                        const tagParser = {
                            id: statement => (tags.id = tagRegex.id.exec(statement)[1], statement.replace(tagRegex.id, "")),
                            data: statement => (tags.data = tagRegex.data.exec(statement)[1], statement.replace(tagRegex.data, "")),
                            emissive: statement => (tags.emissive = 1, statement.replace(tagRegex.emissive, "")),
                        }

                        let statement = section[i]
                        let tag = tagRegex.tag.exec(statement)?.[1]
                        if (!tag) throw new Error(`PropertiesFile > parseData() : No tag matched in '${statement}'`)

                        while ( tagRegex.tag.test(statement) ) {
                            let tag   = tagRegex.tag.exec(statement)[1]
                            statement = tagParser[ tag ]( statement )
                        }
                        if ( statement[0] != "=" ) throw new Error("Expected '=' at end of tag list")

                        statement = statement.replace(/^=\s*/, "")
                        let targets = statement.split(/\s+/)
                        for ( const target of targets ) {
                            targetSection[target] ??= {}
                            targetSection[target].id       ??= tags.id
                            targetSection[target].data     ??= tags.data
                            targetSection[target].emissive ??= tags.emissive
                        }
                    }
                    targetSections.push(targetSection)
                } else if ( section.type == "preprocessor" ) {
                    targetSections.push(section)
                }
            }
            return targetSections
        }

    }

    /** @param {( number, number, number ) => number} packingFunction @returns {string} */
    compileFromTargets( packingFunction ) {
        let compiledSections = []
        for ( const section of this.fileObject ) {
            if ( section.type == "preprocessor" ) compiledSections.push( section )
            if ( section.type == "data" ) {
                let compiledSection = {}
                for ( const target in section ) {
                    if ( target == "type" ) continue;
                    let targetObj = section[ target ]
                    // Handle out-of-rangee values
                    if ( targetObj.id > 255 )     console.warn(`WARNING: '${target}': tag 'id' out of range (${targetObj.id}, range: [0-255])`)
                    if ( targetObj.emissive > 1 ) console.warn(`WARNING: '${target}': tag 'emissive' out of range (${targetObj.emissive}, range: [boolean])`)
                    if ( targetObj.data > 63 )    console.warn(`WARNING: '${target}': tag 'data' out of range (${targetObj.data}, range: [0-63])`)

                    // Pack values
                    let packed    = packingFunction( targetObj.id, targetObj.emissive, targetObj.data )
                    if ( compiledSection[ packed ] == undefined ) compiledSection[ packed ] = []
                    compiledSection[ packed ].push( target )
                }
                compiledSections.push(compiledSection)
            }
        }
        
        let compiledString = ""
        for ( const section of compiledSections ) {
            if ( section.type == "preprocessor" ) compiledString += section[0] + "\n"
            else compiledString += Object.keys( section ).map( key => {
                return `${this.prefix}.${key}=${section[key].join(" ")}`
            }).join("\n") + "\n"
        }

        return compiledString
    }

    static pack( bits = [ 8, 1, 7 ] ) {
        console.log(`pack(): Building Packing Function for ${bits.length} data points, to a ${bits.reduce((acc,curr)=>acc+curr,0)} bit integer`)

    }

}


function packData( id, emissive, data ) {
    let out = 0;
    out  = ~~data << 9
    out |= ~~emissive << 8
    out |= ~~id
    return out
}


const fext  = path => path.match(/.*\.(\w+)$/)?.[1]
const fname = path => path.match(/.*\/([\w\.]*)\.\w+$/)?.[1]
const ffull = path => `${fname(path)}.${fext(path)}`

/** @param {string} path */
function loadProperties( path ) {
    let content = fs.readFileSync(path, {encoding: "utf8"})
    return new PropertiesFile( path, content, fname(path) )
}
/** @param {PropertiesFile} propertiesFile */
function compileProperties( propertiesFile ) {
    let compiled = propertiesFile.compileFromTargets(packData)
    fs.writeFileSync(`${propertiesFile.path}`, compiled )
}


module.exports = {
    PropertiesFile,
    loadProperties,
    compileProperties,
}