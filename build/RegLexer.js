// Token class
export class Token {
    /** @param {Symbol} type @param {string} text */
    constructor( type, text ) {
        this.type = type
        this.text = text
        /** @type {{[property: string]: any, ignore: boolean, merge: boolean}} */
        this.props = {
            ignore: false,
            merge: false
        }
    }

    toString() {
        return this.text
    }
}

// TokenMatcher class
export class TokenMatcher {
    /** @param {Symbol} type @param {RegExp} regex @param {(token: Token, match: RegExpExecArray) => void} parser */
    constructor( type, regex, parser ) {
        this.type = type
        this.regex = regex
        this.parser = parser
    }
}

export class Lexer {
    /** @param {TokenMatcher[]} matchers @param {Symbol} errorSymbol  */
    constructor( matchers, errorSymbol ) {
        this.matchers = matchers
        this.errorSymbol = errorSymbol
    }

    /**
     * Tokenizes the input text based on the defined TokenMatchers.
     * If multiple matches exist, chooses the longest match.
     * Matches each token only once.
     * @param {string} text - The input text to be tokenized.
     * @returns {Token|null} The tokenized result, or null if no match is found.
     */
    next( text ) {
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
        const token = new Token( matcher.type, match[0] )
        if ( matcher.parser ) matcher.parser( token, match )
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

        while ( remaining.length > 0 ) {
            const token = this.next( remaining )
            if ( !token ) {
                // If no token found, add an error token and advance text by one character
                tokens.push( new Token( this.errorSymbol, remaining[0] ) )
                remaining = remaining.slice( 1 )
            } else {
                if ( !token.props.ignore ) {
                    if ( !token.props.merge || tokens.length === 0 || tokens[tokens.length - 1].type !== token.type ) {
                        tokens.push( token )
                    } else {
                        tokens[tokens.length - 1].text += token.text
                    }
                }
                remaining = remaining.slice( token.text.length ) // Remove matched token from remaining text
            }
        }

        return tokens
    }
}




