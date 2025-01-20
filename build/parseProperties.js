import fs from "fs"
import util from "util"
import path from "path"
import url from "url"
import { Lexer, Parser, Token, TokenMatcher } from "./RegLexer.js"

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

const TokenType = Object.freeze( {
    Preprocessor: "Preprocessor",
    Comment: "Comment",
    Whitespace: "Whitespace",
    EscapedNewline: "EscapedNewline",

    Key: "Key",
    Value: "Value",

    Newline: "Newline",
    Dot: "Dot",
    Equals: "Equals",
    Char: "Char",

    Error: "Error",
    Eof: "Eof",
} )

const Tokens = [
    new TokenMatcher( TokenType.Preprocessor, /#(define|undef|if|ifdef|ifndef|elif|else|endif)(\\\r?\n|.)*/ ),
    new TokenMatcher( TokenType.Comment, /#(\\\r?\n|.)*|\/\/.*/, { ignore: true } ),
    new TokenMatcher( TokenType.Whitespace, /([^\S\r\n]|\r(?!\n))+/, { ignore: true } ),
    new TokenMatcher( TokenType.EscapedNewline, /\\\r?\n/, { ignore: true } ),

    new TokenMatcher( TokenType.Newline, /(\r?\n)+/, { merge: true } ),
    new TokenMatcher( TokenType.Equals, /=/ ),

    new TokenMatcher( TokenType.Key, /(?<!\\\r?\n)(?<=\r?\n).*?(?==)/ ),
    new TokenMatcher( TokenType.Value, /.*/, { merge: true } ),
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
    /** @param {string} key @param {string} value  */
    constructor( key, value ) {
        this.key = key.split( "." )
        this.value = value.trim()
    }
}

class PropertiesParser extends Parser {
    eof() {
        return this.peek().type === TokenType.Eof
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
        const key = this.advance( TokenType.Key ).text
        this.advance( TokenType.Equals )
        const value = this.eof() || this.peek().type === TokenType.Newline ? "" : this.advance( TokenType.Value ).text
        return new Property( key, value )
    }
}

export function parseLang( text ) {
    const tokens = new Lexer( Tokens, TokenType.Error, TokenType.Eof ).lex( text )
    const ast = new PropertiesParser( tokens ).parse()[0]
    return ast
}

/* const enUsLang = fs.readFileSync( path.join( __dirname, "../src", "lang", "en_us.lang" ), "utf8" )
const tokens = new Lexer(Tokens, TokenType.Error, TokenType.Eof).lex(enUsLang)
const ast = new PropertiesParser(tokens).parse()[0]
console.log(ast) */