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
            for ( const section of sections ) {
                if ( section.type == "data" ) for ( let i = 0; i < section.length; i++ ) {
                    const statement = section[i]
                    if (/^id/.test(statement)) section[i] = parseId(statement)
                    if (/^data/.test(statement)) section[i] = parseData(statement)
                    if (/^emissive/.test(statement)) section[i] = parseEmissive(statement)
                }
            }
            return sections

            /** @param {string} line */
            function parseId( line ) {
                let id      = line.match(/[a-z]+\.(\d+)\s*=/)[1]
                let targets = line.match(/[a-z]+\.\d+\s*=\s*(.*)/)[1].split(" ")
                return {
                    data: "id",
                    value: +id, // keep number
                    targets: targets
                }
            }
            function parseData( line ) {
                let data    = line.match(/[a-z]+\.(\d+)\s*=/)[1]
                let targets = line.match(/[a-z]+\.\d+\s*=\s*(.*)/)[1].split(" ")
                return {
                    data: "data",
                    value: +data, // keep number
                    targets: targets
                }
            }
            function parseEmissive( line ) {
                //let emissive = line.match(/[a-z]+\s*=/)[1]
                let targets  = line.match(/emissive\s*=\s*(.*)/)[1].split(" ")
                return {
                    data: "emissive",
                    value: 1,
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
                    const targets = { type: "data" }
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
                return `block.${key}=${section[key].join(" ")}`
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
    out  =  ~~id << 8;
    out |= (~~emissive & 1) << 7;
    out |= (~~data & 127)
    return out
}

const blockProperties = fs.readFileSync(__dirname + "/block.properties", {encoding: "utf8"})

let compiled = new PropertiesFile(blockProperties).compileFromTargets( packData )

//console.log(compiled)

fs.writeFileSync(__dirname + "/block.properties.out", compiled)
