import fs from "fs"
import util from "util"
import path from "path"
import url from "url"
import { Lexer, Token, TokenMatcher } from "./RegLexer.js"

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

function packID( id, emissive, data ) {
    id = id & 255
    emissive = emissive & 1
    data = data & 63

    let out = 0
    out |= id
    out |= emissive << 8
    out |= data << 9
    return out
}

const TokenType = Object.freeze( {
    Preprocessor: "Preprocessor",
    Comment: "Comment",
    Whitespace: "Whitespace",
    EscapedNewline: "EscapedNewline",

    Ident: "Ident",
    Number: "Number",

    Newline: "Newline",
    Dot: "Dot",
    Equals: "Equals",

    Error: "Error",
    Eof: "Eof",
} )

const Tokens = [
    new TokenMatcher( TokenType.Preprocessor, /#(define|undef|if|ifdef|ifndef|elif|else|endif)(\\\r?\n|.)*/ ),
    new TokenMatcher( TokenType.Comment, /#(\\\r?\n|.)*/, { ignore: true } ),
    new TokenMatcher( TokenType.Whitespace, /([^\S\r\n]|\r(?!\n))+/, { ignore: true } ),
    new TokenMatcher( TokenType.EscapedNewline, /\\\r?\n/, { ignore: true } ),

    new TokenMatcher( TokenType.Ident, /[a-zA-Z_][a-zA-Z0-9_]*(:[a-zA-Z_][a-zA-Z0-9_]*(=[a-zA-Z_][a-zA-Z0-9_]*)?)*/ ),
    new TokenMatcher( TokenType.Number, /[+-]?\d+/, token => token.props.value = +token.text ),

    new TokenMatcher( TokenType.Newline, /(\r?\n)+/, { merge: true } ),
    new TokenMatcher( TokenType.Dot, /\./ ),
    new TokenMatcher( TokenType.Equals, /=/ ),
]

class Block extends Array {
    /** @param {"preprocessor"|"properties"} type */
    constructor( type ) {
        super()
        this.type = type
    }
}
class Preprocessor {
    /** @param {string} token */
    constructor( token ) {
        this.token = token
    }
}
class Property {
    /** @param {string[]} properties @param {string[]} targets  */
    constructor( properties, targets ) {
        this.properties = properties
        this.targets = targets
    }
}

class PropertiesParser {
    /** @param {Token<string>[]} tokens */
    constructor( tokens ) {
        this.tokens = tokens
        this.index = 0
    }

    eof() {
        return this.tokens[this.index].type === TokenType.Eof
            || this.index >= this.tokens.length
    }
    peek( lookahead = 0 ) {
        return this.tokens[this.index + lookahead]
    }
    advance( ...types ) {
        const token = this.tokens[this.index++]
        if ( types.length && !types.includes( token.type ) ) {
            throw new Error( `Expected ${types.map( t => t.toString() ).join( " or " )} but got ${token.type.toString()}` )
        }
        return token
    }
    advanceIf( ...types ) {
        const token = this.tokens[this.index]
        if ( types.includes( token.type ) ) {
            this.index++
            return true
        }
        return false
    }

    parse() {
        return this.parseBlocks()
    }
    parseBlocks() {
        let blocks = []
        while ( !this.eof() ) {
            while ( this.advanceIf( TokenType.Newline ) ) {}
            const ttype = this.peek().type
            if ( ttype === TokenType.Preprocessor ) {
                const node = this.parsePreprocessor()
                if ( blocks.at( -1 )?.type !== "preprocessor" ) blocks.push( new Block( "preprocessor" ) )
                blocks.at( -1 ).push( node )
            } else {
                const node = this.parseProperty()
                if ( blocks.at( -1 )?.type !== "properties" ) blocks.push( new Block( "properties" ) )
                blocks.at( -1 ).push( node )
            }
        }
        return blocks
    }
    parsePreprocessor() {
        const token = this.advance( TokenType.Preprocessor )
        return new Preprocessor( token.toPrimitive() )
    }
    parseProperty() {
        let properties = []
        let targets = []
        properties.push( this.advance( TokenType.Ident ) )
        while ( this.advanceIf( TokenType.Dot ) ) {
            properties.push( this.advance( TokenType.Ident, TokenType.Number ) )
        }
        this.advance( TokenType.Equals )
        while ( !this.advanceIf( TokenType.Newline ) ) {
            targets.push( this.advance( TokenType.Ident ) )
        }
        return new Property( properties.map( t => t.toPrimitive() ), targets.map( t => t.toPrimitive() ) )
    }
}

function parseProperties( text ) {
    const lexer = new Lexer( Tokens, TokenType.Error, TokenType.Eof )
    const tokens = lexer.lex( text )
    const parser = new PropertiesParser( tokens )
    const blocks = parser.parse()
    return blocks
}

/** @param {Block[]} blocks @param {string} prefix  */
function compileProperties( blocks, prefix ) {
    /** @param {Block} block  */
    function compileBlock( block ) {
        if ( block.type === "preprocessor" ) return block.map( n => n.token.trim() ).join( "\n" )

        const targets = new Map

        // Accumulate properties
        for ( const { properties: props, targets: t } of block ) {
            const properties = {}
            for ( let i = 0; i < props.length; i++ ) {
                const p = props[i], v = props[i + 1]
                properties[p] = typeof v === "number" ? ( ++i, v ) : 1
            }
            for ( const target of t ) {
                if ( !targets.has( target ) ) targets.set( target, properties )
                else Object.assign( targets.get( target ), properties )
            }
        }

        // Compile properties
        for ( const [target, { id, emissive, data }] of targets.entries() ) {
            targets.set( target, packID( id, emissive, data ) )
        }

        const inverted = new Map

        for ( const [target, value] of targets.entries() ) {
            if ( !inverted.has( value ) ) inverted.set( value, [] )
            inverted.get( value ).push( target )
        }

        const compiled = [...inverted.entries()]
            .map( ( [value, targets] ) => `${prefix}.${value} = ${targets.join( " " )}` )
            .join( "\n" )
        return compiled
    }

    return blocks.map( compileBlock ).join( "\n\n" )
}

/** @param {string} filepath */
export function compilePropertiesFile( filepath ) {
    const prefix = path.basename( filepath, ".properties" )
    const content = fs.readFileSync( filepath, { encoding: "utf8" } )
    const compiled = compileProperties( parseProperties( content ), prefix )
    fs.writeFileSync( filepath, compiled )
}