// Position class
export class Position {
    /** @param {number} index @param {number} line @param {number} column */
    constructor( index, line, column ) {
        this.index = index
        this.line = line
        this.column = column
    }

    /** @param {string} text */
    advance( text ) {
        for ( const char of text ) {
            this.index++
            this.column++
            if ( char === '\n' ) {
                this.line++
                this.column = 1
            }
        }
        return this
    }

    clone() {
        return new Position( this.index, this.line, this.column )
    }
}

// Range class
export class Range {
    /** @param {Position} start @param {Position} end */
    constructor( start, end ) {
        this.start = start
        this.end = end
    }

    get length() {
        return this.end.index - this.start.index
    }

    clone() {
        return new Range( this.start.clone(), this.end.clone() )
    }
}

// Token class
/**
 * @typedef {{[property: string]: any, ignore: boolean, merge: boolean, value?: boolean|number|string}} TokenProperties
 */
/** @template {string} T */
export class Token {
    /** @param {T} type @param {string} text @param {Range} range */
    constructor( type, text, range ) {
        this.type = type
        this.text = text
        this.range = range
        /** @type {TokenProperties} */
        this.props = {
            ignore: false,
            merge: false
        }
    }

    get position() {
        return this.range.start
    }

    toString() {
        return this.text
    }
    toPrimitive() {
        return this.props.value ?? this.text
    }
}

// TokenMatcher class
/** @template {string} T */
export class TokenMatcher {
    static compileRegex( regex ) {
        return new RegExp( `^(?:${regex.source})` )
    }

    /** @param {T} type @param {RegExp} regex @param {TokenProperties|(token: Token, match: RegExpExecArray) => void} parser @param {{[property:string]:any}} props */
    constructor( type, regex, parser, props = {} ) {
        this.type = type
        this.regex = TokenMatcher.compileRegex( regex )
        this.parser = parser
        this.props = props
    }
}

// Lexer class
/** @template {string} T */
export class Lexer {
    /** @param {TokenMatcher<T>[]} matchers @param {T} errorToken @param {T} eofToken */
    constructor( matchers, errorToken, eofToken, { postprocess = true } = {} ) {
        this.matchers = matchers
        this.errorToken = errorToken
        this.eofToken = eofToken
        this.props = { postprocess }
    }

    /**
     * Tokenizes the input text based on the defined TokenMatchers.
     * If multiple matches exist, chooses the longest match.
     * Matches each token only once.
     * @param {string} text - The input text to be tokenized.
     * @param {Position} position - The current position in the input text.
     * @returns {Token<T>|null} The tokenized result, or null if no match is found.
     */
    next( text, position ) {
        let match, matcher
        for ( const x of this.matchers ) {
            const m = x.regex.exec( text )
            if ( m ) {
                match = m
                matcher = x
                break
            }
        }
        if ( !match ) return null

        const token = new Token( matcher.type, match[0], new Range( position.clone(), position.clone().advance( match[0] ) ) )
        if ( matcher.parser ) {
            if ( typeof matcher.parser === 'function' ) {
                matcher.parser( token, match )
            }
            if ( typeof matcher.parser === 'object' ) {
                token.props = { ...token.props, ...matcher.parser }
            }
        }
        return token
    }

    /**
     * Tokenizes the input text based on the defined TokenMatchers.
     * Matches all tokens in the input text.
     * @param {string} text - The input text to be tokenized.
     * @returns {Token<T>[]} An array of tokenized results.
     */
    lex( text ) {
        const tokens = []
        let remaining = text
        let position = new Position( 0, 1, 1 )

        while ( remaining.length > 0 ) {
            const token = this.next( remaining, position )

            if ( !token ) {
                // If no token found, add an error token and advance text by one character
                tokens.push( new Token( this.errorToken, remaining[0], new Range( position.clone(), position.clone().advance( remaining[0] ) ) ) )
                position.advance( remaining[0] )
                remaining = remaining.slice( 1 )
                continue
            }

            if ( this.props.postprocess ) {

                if ( !token.props.ignore ) {
                    if ( !token.props.merge || tokens.length === 0 || tokens[tokens.length - 1].type !== token.type ) {
                        tokens.push( token )
                    } else {
                        tokens[tokens.length - 1].text += token.text
                        tokens[tokens.length - 1].range.end = token.range.end.clone() // Update end position of merged token range
                    }
                }

            } else {
                tokens.push( token )
            }

            position.advance( token.text )
            remaining = remaining.slice( token.text.length ) // Remove matched token from remaining text
        }

        tokens.push( new Token( this.eofToken, '', new Range( position.clone(), position.clone() ) ) ) // Add EOF token at end of text
        return tokens
    }
}

// Parser class
/** @template {string} T */
export class Parser {
    /** @param {Token<T>[]} tokens */
    constructor( tokens ) {
        this.tokens = tokens
        this.index = 0
    }

    /** @param {number} [lookahead=0] */
    peek( lookahead = 0 ) {
        return this.tokens[this.index + lookahead]
    }
    /** @param {...T} types */
    advance( ...types ) {
        const token = this.tokens[this.index++]
        if ( types.length && !types.includes( token.type ) ) {
            throw new Error( `Expected ${types.join( " or " )} but got ${token.type} "${token.text}" at [l:${token.position.line} c:${token.position.column}]` )
        }
        return token
    }
    /** @param {...T} types */
    advanceIf( ...types ) {
        const token = this.tokens[this.index]
        if ( types.length && types.includes( token.type ) ) {
            this.index++
            return token
        }
    }
}

