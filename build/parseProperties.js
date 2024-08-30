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
    Char: "Char",

    Error: "Error",
    Eof: "Eof",
} )

const Tokens = [
    new TokenMatcher( TokenType.Preprocessor, /#(define|undef|if|ifdef|ifndef|elif|else|endif)(\\\r?\n|.)*/ ),
    new TokenMatcher( TokenType.Comment, /#(\\\r?\n|.)*/, { ignore: true } ),
    new TokenMatcher( TokenType.Whitespace, /([^\S\r\n]|\r(?!\n))+/, { ignore: true } ),
    new TokenMatcher( TokenType.EscapedNewline, /\\\r?\n/, { ignore: true } ),

    new TokenMatcher( TokenType.Ident, /[[<]?[a-zA-Z_][a-zA-Z0-9_\-/]*(:[a-zA-Z_][a-zA-Z0-9_\-/]*(=[a-zA-Z_][a-zA-Z0-9_\-/]*)?)*[\]>]?/ ),
    new TokenMatcher( TokenType.Number, /[+-]?\d+/, token => token.props.value = +token.text ),

    new TokenMatcher( TokenType.Newline, /(\r?\n)+/, { merge: true } ),
    new TokenMatcher( TokenType.Dot, /\./ ),
    new TokenMatcher( TokenType.Equals, /=/ ),
    new TokenMatcher( TokenType.Char, /./ ),
]

/** @extends {Array<Preprocessor|Property>} */
class Block extends Array {
    /** @param {"preprocessor"|"properties"} type */
    constructor( type ) {
        super()
        this.type = type
    }
}
class Preprocessor {
    /** @param {string} text */
    constructor( text ) {
        this.text = text
    }
}
class Property {
    /** @param {string[]} key @param {string[]} value  */
    constructor( key, value ) {
        this.key = key
        this.value = value
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
            throw new Error( `Expected ${types.join( " or " )} but got ${token.type} "${token.text}" at [l:${token.position.line} c:${token.position.column}]` )
        }
        return token
    }
    advanceIf( ...types ) {
        const token = this.tokens[this.index]
        if ( types.includes( token.type ) ) {
            this.index++
            return token
        }
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
        let key = []
        let value = []
        let valueIsIdentifierList = true
        key.push( this.advance( TokenType.Ident ).toPrimitive() )
        while ( this.advanceIf( TokenType.Dot ) ) {
            key.push( this.advance( TokenType.Ident, TokenType.Number ).toPrimitive() )
        }
        this.advance( TokenType.Equals )
        while ( !this.advanceIf( TokenType.Newline ) ) {
            if ( !valueIsIdentifierList ) {
                value[0] += this.advanceIf( TokenType.Char )?.text ?? " " + this.advance().text
            } else if ( this.peek().type === TokenType.Ident ) {
                value.push( this.advance( TokenType.Ident ).toPrimitive() )
            } else {
                valueIsIdentifierList = false
                value = [value.join( " " ) + this.advanceIf( TokenType.Char )?.text ?? " " + this.advance().text]
            }
        }
        return new Property( key, value )
    }
}

export function parseProperties( text ) {
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
        if ( block.type === "preprocessor" ) return block.map( n => n.text.trim() ).join( "\n" )

        const targets = new Map

        // Accumulate properties
        for ( const { key: props, value: propTargets } of block ) {
            const properties = {}
            for ( let i = 0; i < props.length; i++ ) {
                const p = props[i], v = props[i + 1]
                properties[p] = typeof v === "number" ? ( ++i, v ) : 1
            }
            for ( const target of propTargets ) {
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
    const content = fs.readFileSync( filepath, "utf8" )
    const compiled = compileProperties( parseProperties( content ), prefix )
    fs.writeFileSync( filepath, compiled )
}