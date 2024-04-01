import fs from "fs"
import util from "util"
import path from "path"
import url from "url"
import { Lexer, Token, TokenMatcher } from "./RegLexer.js"

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

export class PropertiesFile {
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
            return txt.replace( /\s*\\\s*\n/g, "" )
        }
        function parseComments( txt ) { // Removes Comments
            return txt.replace( /#(?!if|ifdef|ifndef|elif|else|endif|define|undef).*$/gm, "" )
        }
        function trimSpaces( txt ) { // Removes excess spaces and newlines
            return txt.replace( /[ \t]+/g, " " ).replace( /\s*\n\s*/g, "\n" ).trim()
        }

        function parseScope( txt ) { // Splits the code up into sections

            let sections = []
            for ( const line of txt.split( "\n" ) ) {
                let lineType = getLineType( line )
                if ( lineType == sections[sections.length - 1]?.type ) {
                    sections[sections.length - 1].push( line )
                } else {
                    sections.push( Object.assign( [line], { type: lineType } ) )
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
                            id: statement => ( tags.id = tagRegex.id.exec( statement )[1], statement.replace( tagRegex.id, "" ) ),
                            data: statement => ( tags.data = tagRegex.data.exec( statement )[1], statement.replace( tagRegex.data, "" ) ),
                            emissive: statement => ( tags.emissive = 1, statement.replace( tagRegex.emissive, "" ) ),
                        }

                        let statement = section[i]
                        let tag = tagRegex.tag.exec( statement )?.[1]
                        if ( !tag ) throw new Error( `PropertiesFile > parseData() : No tag matched in '${statement}'` )

                        while ( tagRegex.tag.test( statement ) ) {
                            let tag = tagRegex.tag.exec( statement )[1]
                            statement = tagParser[tag]( statement )
                        }
                        if ( statement[0] != "=" ) throw new Error( "Expected '=' at end of tag list" )

                        statement = statement.replace( /^=\s*/, "" )
                        let targets = statement.split( /\s+/ )
                        for ( const target of targets ) {
                            targetSection[target] ??= {}
                            targetSection[target].id ??= tags.id
                            targetSection[target].data ??= tags.data
                            targetSection[target].emissive ??= tags.emissive
                        }
                    }
                    targetSections.push( targetSection )
                } else if ( section.type == "preprocessor" ) {
                    targetSections.push( section )
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
                    if ( target == "type" ) continue
                    let targetObj = section[target]
                    // Handle out-of-rangee values
                    if ( targetObj.id > 255 ) console.warn( `WARNING: '${target}': tag 'id' out of range (${targetObj.id}, range: [0-255])` )
                    if ( targetObj.emissive > 1 ) console.warn( `WARNING: '${target}': tag 'emissive' out of range (${targetObj.emissive}, range: [boolean])` )
                    if ( targetObj.data > 63 ) console.warn( `WARNING: '${target}': tag 'data' out of range (${targetObj.data}, range: [0-63])` )

                    // Pack values
                    let packed = packingFunction( targetObj.id, targetObj.emissive, targetObj.data )
                    if ( compiledSection[packed] == undefined ) compiledSection[packed] = []
                    compiledSection[packed].push( target )
                }
                compiledSections.push( compiledSection )
            }
        }

        let compiledString = ""
        for ( const section of compiledSections ) {
            if ( section.type == "preprocessor" ) compiledString += section[0] + "\n"
            else compiledString += Object.keys( section ).map( key => {
                return `${this.prefix}.${key}=${section[key].join( " " )}`
            } ).join( "\n" ) + "\n"
        }

        return compiledString
    }

    static pack( bits = [8, 1, 7] ) {
        console.log( `pack(): Building Packing Function for ${bits.length} data points, to a ${bits.reduce( ( acc, curr ) => acc + curr, 0 )} bit integer` )

    }

}

export class PropertiesParser {
    /** @param {string} text */
    constructor( text ) {
        /** @type {string} */
        this.text = text
    }

    /** @returns {{properties: string[], targets: string[]}[]} */
    parse() {

        this.text = this.text.replace( /[\t ]*\\[\t ]*\n/g, "" )
        this.text = this.text.replace( /#.*/g, "" )
        this.text = this.text.replace( /\s*\n\s*/g, "\n" ).replace( /[\t ]+/, " " ).trim()

        const lines = this.text.split( "\n" )
        const parsedLines = []
        for ( const line of lines ) {
            let properties = /^([^=]*)=/.exec( line )[1]
            let targets = /^[^=]*=(.*)/.exec( line )[1]

            properties = properties.split( "." )
            targets = targets.split( " " )

            parsedLines.push( {
                properties: properties,
                targets: targets
            } )
        }

        return parsedLines

    }
}
export class PropertiesCompiler {
    constructor( text ) {
        this.lines = new PropertiesParser( text ).parse()
    }

    parseProperties() {
        for ( let i = 0; i < this.lines.length; i++ ) {

            const line = this.lines[i]
            const properties = line.properties

            const parsed = []
            let token
            while ( properties.length > 0 ) {
                const nextToken = properties.splice( 0, 1 )
                if ( nextToken == "emissive" ) {
                    parsed.push( { property: "emissive", value: 1 } )
                    token = undefined
                    continue
                }
                if ( nextToken == "id" ) {
                    token = { property: "id", value: null }
                    continue
                }
                if ( nextToken == "data" ) {
                    token = { property: "data", value: null }
                    continue
                }

                if ( isFinite( +nextToken ) ) {
                    if ( !token ) throw new Error( `Cannot assign value to undefined property` )
                    token.value = +nextToken
                    parsed.push( token )
                    token = undefined
                }
            }

            this.lines[i].properties = parsed
        }

        return this
    }

    orientTarget() {

        const targets = []
        for ( let i = 0; i < this.lines.length; i++ ) {
            const line = this.lines[i]
            for ( const target of line.targets ) {
                const index = targets.findIndex( ele => ele.target == target )

                if ( index == -1 ) {
                    targets.push( {
                        target: target,
                        properties: line.properties
                    } )
                    continue
                }

                for ( const property of line.properties ) {
                    const propertyIndex = targets[index].properties.findIndex( prop => prop.property == property.property )

                    if ( propertyIndex == -1 ) {
                        targets[index].properties.push( property )
                        continue
                    }

                    targets[index].properties[propertyIndex].value = property.value
                }

            }
        }

        this.targets = targets
        return this
    }

}

function packData( id, emissive, data ) {
    let out = 0
    out = ~~data << 9
    out |= ~~emissive << 8
    out |= ~~id
    return out
}


const fext = path => path.match( /.*\.(\w+)$/ )?.[1]
const fname = path => path.match( /.*\/([\w\.]*)\.\w+$/ )?.[1]
const ffull = path => `${fname( path )}.${fext( path )}`

/** @param {string} path */
export function loadProperties( path ) {
    let content = fs.readFileSync( path, { encoding: "utf8" } )
    return new PropertiesFile( path, content, fname( path ) )
}
/** @param {PropertiesFile} propertiesFile */
export function compileProperties( propertiesFile ) {
    let compiled = propertiesFile.compileFromTargets( packData )
    fs.writeFileSync( `${propertiesFile.path}`, compiled )
}

export function parseProperties( text ) {

    const TokenType = Object.freeze( {
        Whitespace: Symbol( "Whitespace" ),
        EscapedNewline: Symbol( "EscapedNewline" ),
        Comment: Symbol( "Comment" ),

        Ident: Symbol( "Ident" ),
        Number: Symbol( "Number" ),

        Newline: Symbol( "Newline" ),
        Dot: Symbol( "Dot" ),
        Equals: Symbol( "Equals" ),

        EqualsEquals: Symbol( "EqualsEquals" ),
        Greater: Symbol( "Greater" ),
        GreaterEquals: Symbol( "GreaterEquals" ),
        Less: Symbol( "Less" ),
        LessEquals: Symbol( "LessEquals" ),

        If: Symbol( "If" ),
        Ifdef: Symbol( "Ifdef" ),
        Ifndef: Symbol( "Ifndef" ),
        Elif: Symbol( "Elif" ),
        Else: Symbol( "Else" ),
        Endif: Symbol( "Endif" ),

        Error: Symbol( "Error" ),
    } )

    function preprocessorTokenParser( token, match ) {
        if ( match.groups ) {
            for ( const group in match.groups ) {
                token.props[group] = match.groups[group].trim()
            }
        }
    }

    const Tokens = [
        new TokenMatcher( TokenType.Whitespace, /[^\S\n\r]+/, token => token.props.ignore = true ),
        new TokenMatcher( TokenType.Comment, /#(?!define|undef|ifdef|ifndef|if|elif|else|endif).*(\r?\n)?/, token => token.props.ignore = true ),
        new TokenMatcher( TokenType.EscapedNewline, /\\\r?\n/, token => token.props.ignore = true ),

        new TokenMatcher( TokenType.Ident, /[a-zA-Z_][a-zA-Z0-9_]*(:[a-zA-Z_][a-zA-Z0-9_]*(=[a-zA-Z_][a-zA-Z0-9_]*)?)*/ ),
        new TokenMatcher( TokenType.Number, /[+-]?\d+/, token => token.props.value = Number( token.text ) ),

        new TokenMatcher( TokenType.Newline, /(?:\r?\n)+/, token => token.props.merge = true ),
        new TokenMatcher( TokenType.Dot, /\./ ),
        new TokenMatcher( TokenType.Equals, /=/ ),

        new TokenMatcher( TokenType.EqualsEquals, /==/ ),
        new TokenMatcher( TokenType.Greater, />/ ),
        new TokenMatcher( TokenType.GreaterEquals, />=/ ),
        new TokenMatcher( TokenType.Less, /</ ),
        new TokenMatcher( TokenType.LessEquals, /<=/ ),

        new TokenMatcher( TokenType.If, /#define[^\S\n\r]+(?<identifier>.*)/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Ifdef, /#undef[^\S\n\r]+(?<identifier>.*)/, preprocessorTokenParser ),

        new TokenMatcher( TokenType.If, /#if[^\S\n\r]+(?<condition>.*)/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Ifdef, /#ifdef[^\S\n\r]+(?<condition>.*)/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Ifndef, /#ifndef[^\S\n\r]+(?<condition>.*)/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Elif, /#elif[^\S\n\r]+(?<condition>.*)/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Else, /#else/, preprocessorTokenParser ),
        new TokenMatcher( TokenType.Endif, /#endif/, preprocessorTokenParser ),
    ]

    class Node {}
    class ConditionalBlock extends Node {
        /** @param {Symbol} directive @param {string=} condition @param {Node[]} block */
        constructor( directive, condition, block ) {
            super()
            this.directive = directive
            this.condition = condition
            this.nodes = block
        }
    }
    class ConditionalNode extends Node {
        /** @param {ConditionalBlock[]} blocks */
        constructor( blocks ) {
            super()
            this.blocks = blocks
        }
    }
    class AssignmentNode extends Node {
        constructor( properties, targets ) {
            super()
            this.properties = properties
            this.targets = targets
        }
    }

    class Parser {
        /** @param {Token[]} tokens */
        constructor( tokens ) {
            this.tokens = tokens
            this.index = 0
        }

        eof() {
            return this.index >= this.tokens.length
        }
        next( ...types ) {
            const token = this.tokens[this.index++]
            if ( types.length > 0 && !types.includes( token.type ) ) {
                throw new Error( `Expected ${types.join( " or " )}, got '${token.type}'` )
            }
            return token
        }
        nextIf( ...types ) {
            const token = this.tokens[this.index]
            if ( !this.eof() && types.includes( token.type ) ) {
                this.index++
                return true
            }
            return false
        }
        peek( lookahead = 0 ) {
            return this.tokens[this.index + lookahead]
        }

        parse() {
            return this.parseBlock()
        }
        parseBlock() {
            let block = []
            while ( !this.eof() ) {
                const statement = this.parseStatement()
                if ( !statement ) break
                block.push( statement )
            }
            return block
        }
        parseStatement() {
            const token = this.peek()
            switch ( token.type ) {
                case TokenType.If:
                case TokenType.Ifdef:
                case TokenType.Ifndef:
                    return this.parseConditional()
                case TokenType.Ident:
                    return this.parseAssignment()
            }
        }
        parseConditional() {
            const directive = this.next()
            const condition = directive.props.condition
            this.nextIf( TokenType.Newline )

            const blocks = [new ConditionalBlock(
                directive.type,
                condition,
                this.parseBlock()
            )]

            while ( this.peek().type === TokenType.Elif ) {
                const elif = this.next()
                const elifCondition = elif.props.condition
                this.nextIf( TokenType.Newline )

                blocks.push( new ConditionalBlock(
                    elif.type,
                    elifCondition,
                    this.parseBlock()
                ) )
            }

            if ( this.peek().type === TokenType.Else ) {
                const elseDirective = this.next()
                this.nextIf( TokenType.Newline )

                blocks.push( new ConditionalBlock(
                    elseDirective.type,
                    undefined,
                    this.parseBlock()
                ) )
            }

            if ( this.nextIf( TokenType.Endif ) ) {
                this.nextIf( TokenType.Newline )
                return new ConditionalNode( blocks )
            }

            throw new Error( `Expected 'elif', 'else', or 'endif', got '${this.peek().type.toString()}'` )
        }
        parseAssignment() {
            const properties = []
            while ( this.peek().type === TokenType.Ident ) {
                const property = { name: "", value: 1 }

                property.name = this.next().text
                if ( this.peek().type === TokenType.Dot ) {
                    this.next()
                    if ( this.peek().type === TokenType.Number ) {
                        property.value = this.next().props.value
                        this.nextIf( TokenType.Dot )
                    }
                }

                properties.push( property )
            }

            this.next( TokenType.Equals )

            const targets = []
            while ( this.peek().type === TokenType.Ident ) {
                targets.push( this.next().text )
            }

            this.next( TokenType.Newline )

            return new AssignmentNode( properties, targets )
        }

    }

    class Visitor {
        /**@param {Node} node */
        visitHook( node ) {}

        /**@param {Node|Node[]} node */
        visit( node ) {
            if ( node instanceof Array ) {
                return node.forEach( node => this.visit( node ) )
            }

            this.visitHook( node )

            if ( node instanceof ConditionalBlock ) {
                this.visitConditionalBlock( node )
            }
            if ( node instanceof ConditionalNode ) {
                this.visitConditionalNode( node )
            }
            if ( node instanceof AssignmentNode ) {
                this.visitAssignmentNode( node )
            }
        }

        /**@param {ConditionalBlock} node */
        visitConditionalBlock( node ) {
            this.visit( node.nodes )
        }

        /**@param {ConditionalNode} node */
        visitConditionalNode( node ) {
            node.blocks.forEach( node => this.visit( node ) )
        }

        /**@param {AssignmentNode} node */
        visitAssignmentNode( node ) {}
    }

    class CollectingVisitor extends Visitor {
        constructor() {
            super()
            /** @type {Map<ClassDecorator,Node[]>} */
            this.data = new Map( [
                [ConditionalBlock, []],
                [ConditionalNode, []],
                [AssignmentNode, []]
            ] )
        }

        visitHook( node ) {
            this.data.get( node.constructor ).push( node )
        }
    }

    const lexer = new Lexer( Tokens, TokenType.Error )
    const tokens = lexer.lex( text )
    if ( tokens[0]?.type === TokenType.Newline ) tokens.shift()

    const parser = new Parser( tokens )
    const ast = parser.parse()

    const visitor = new CollectingVisitor()
    visitor.visit( ast )

    return visitor
}

let text = fs.readFileSync( path.join( __dirname, "test.conditions.properties" ) ).toString()
let ast = parseProperties( text )

console.log( ast )
//console.log( util.inspect( ast, { showHidden: false, depth: null, colors: true } ) )