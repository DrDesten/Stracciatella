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
export class Token {
    /** @param {Symbol} type @param {string} text @param {Range} range */
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
export class TokenMatcher {
    /** @param {Symbol} type @param {RegExp} regex @param {TokenProperties|(token: Token, match: RegExpExecArray) => void} parser @param {{[property:string]:any}} props */
    constructor( type, regex, parser, props = {} ) {
        this.type = type
        this.regex = regex
        this.parser = parser
        this.props = props
    }
}

export class Lexer {
    /** @param {TokenMatcher[]} matchers @param {Symbol} errorSymbol @param {Symbol} eofSymbol */
    constructor( matchers, errorSymbol, eofSymbol, { postprocess = true } = {} ) {
        this.matchers = matchers
        this.errorSymbol = errorSymbol
        this.eofSymbol = eofSymbol
        this.props = { postprocess }
    }

    /**
     * Tokenizes the input text based on the defined TokenMatchers.
     * If multiple matches exist, chooses the longest match.
     * Matches each token only once.
     * @param {string} text - The input text to be tokenized.
     * @param {Position} position - The current position in the input text.
     * @returns {Token|null} The tokenized result, or null if no match is found.
     */
    next( text, position ) {
        const matches = []

        for ( const matcher of this.matchers ) {
            const regex = matcher.regex
            const match = regex.exec( text )
            if ( match && match.index === 0 ) {
                matches.push( { match, matcher: matcher } )
            }
        }

        matches.sort( ( a, b ) => b.match[0].length - a.match[0].length )

        const longestMatch = matches[0]
        if ( !longestMatch ) return null

        const { match, matcher } = longestMatch
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
     * @returns {Token[]} An array of tokenized results.
     */
    lex( text ) {
        const tokens = []
        let remaining = text
        let position = new Position( 0, 1, 1 )

        while ( remaining.length > 0 ) {
            const token = this.next( remaining, position )

            if ( !token ) {
                // If no token found, add an error token and advance text by one character
                tokens.push( new Token( this.errorSymbol, remaining[0], new Range( position.clone(), position.clone().advance( remaining[0] ) ) ) )
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

        tokens.push( new Token( this.eofSymbol, '', new Range( position.clone(), position.clone() ) ) ) // Add EOF token at end of text
        return tokens
    }
}




