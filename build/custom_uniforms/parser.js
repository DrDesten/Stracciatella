/*
uniform vec2 screenSize        = vec2(viewWidth, viewHeight)
uniform vec2 screenSizeInverse = 1.0 / screenSize

const   float sunLength  = length(sunPosition.xyz)
uniform vec3  sunDir     = sunPosition.xyz / sunLength
const   float moonLength = length(moonPosition)
uniform vec3  moonDir    = moonPosition / moonLength
const   float upLength   = sqrt(dot(gbufferModelView[1].xyz, gbufferModelView[1].xyz))
uniform vec3  up         = vec3(gbufferModelView[1].xyz / upLength)
*/

export const TokenType = {
    NUMBER: 'NUMBER',
    IDENT: 'IDENT',
    PLUS: 'PLUS',
    MINUS: 'MINUS',
    STAR: 'STAR',
    SLASH: 'SLASH',
    EQUALS: 'EQUALS',
    LPAREN: 'LPAREN',
    RPAREN: 'RPAREN',
    LBRACKET: 'LBRACKET',
    RBRACKET: 'RBRACKET',
    DOT: 'DOT',
    COMMA: 'COMMA',
    EOF: 'EOF',
}

const SIMPLE_TOKENS = {
    '+': TokenType.PLUS,
    '-': TokenType.MINUS,
    '*': TokenType.STAR,
    '/': TokenType.SLASH,
    '=': TokenType.EQUALS,
    '(': TokenType.LPAREN,
    ')': TokenType.RPAREN,
    '[': TokenType.LBRACKET,
    ']': TokenType.RBRACKET,
    '.': TokenType.DOT,
    ',': TokenType.COMMA,
}

const Token = ( type, value, pos ) => ( { type, value, pos } )

function Lexer( source, index = 0 ) {
    return {
        next() {
            function peek( n = 0 ) {
                return source[index + n]
            }
            function advance( n = 1 ) {
                const c = source[index]
                index += n
                return c
            }
            function slice() {
                return source.slice( index )
            }

            function advanceWhitespace() {
                let c
                while ( c = peek(), c === ' ' || c === '\t' || c === '\r' || c === '\n' )
                    advance()
            }
            function advanceSingleComment() {
                if ( peek() === '/' && peek( 1 ) === '/' ) while ( peek() != undefined && advance() != '\n' ) {}
            }
            function advanceMultiComment() {
                let level = 0
                if ( peek() === '/' && peek( 1 ) === '*' )
                    advance(), advance(), level++

                while ( level > 0 && peek() != undefined ) {
                    if ( peek() === '*' && peek( 1 ) === '/' )
                        advance(), advance(), level--
                    else if ( peek() === '/' && peek( 1 ) === '*' )
                        advance(), advance(), level++
                    else
                        advance()
                }
            }

            // advance ignored
            while ( true ) {
                let i = index
                advanceWhitespace()
                advanceSingleComment()
                advanceMultiComment()
                if ( i === index ) break
            }

            // tokenize
            let c = peek()
            let s = slice()
            let m
            if ( c === undefined )
                return Token( TokenType.EOF, "", index )
            if ( m = /^(\d+\.?\d*|\.\d+?)([eE][+-]?\d+)?/.exec( s ) ) {
                const token = Token( TokenType.NUMBER, m[0], index )
                advance( m[0].length )
                return token
            }
            if ( SIMPLE_TOKENS[c] ) {
                const token = Token( SIMPLE_TOKENS[c], c, index )
                advance()
                return token
            }
            if ( m = /^\w+/.exec( s ) ) {
                const token = Token( TokenType.IDENT, m[0], index )
                advance( m[0].length )
                return token
            }

            throw new SyntaxError( "Lexer failure" )
        }
    }
}

const Node = {
    Program: ( declarations ) => ( { kind: 'Program', declarations } ),
    Declaration: ( qualifier, valueType, name, expr ) => ( {
        kind: 'Declaration', qualifier, valueType, name, expr,
    } ),
    NumberLiteral: ( value ) => ( { kind: 'NumberLiteral', value } ),
    Identifier: ( name ) => ( { kind: 'Identifier', name } ),
    UnaryExpr: ( op, argument ) => ( { kind: 'UnaryExpr', op, argument } ),
    BinaryExpr: ( op, left, right ) => ( { kind: 'BinaryExpr', op, left, right } ),
    CallExpr: ( name, args ) => ( { kind: 'CallExpr', name, args } ),
    SwizzleExpr: ( target, swizzle ) => ( { kind: 'SwizzleExpr', target, swizzle } ),
    IndexExpr: ( target, index ) => ( { kind: 'IndexExpr', target, index: index.value } ),
}

// ---------------------------------------------------------------------------
// Parser (recursive descent)
//
// Declaration  := ('uniform' | 'const') Ident Ident '=' Expression
// Expression   := Additive
// Additive     := Multiplicative (('+' | '-') Multiplicative)*
// Multiplicative := Unary (('*' | '/') Unary)*
// Unary        := ('+' | '-') Unary | Postfix
// Postfix      := Primary ( '.' Ident | '[' Expression ']' | '(' Args ')' )*
// Primary      := Number | Ident | '(' Expression ')'
// Args         := (Expression (',' Expression)*)?
// ---------------------------------------------------------------------------

const QUALIFIERS = new Set( ['uniform', 'const'] )

class Parser {
    constructor( source ) {
        this.lexer = Lexer( source )
        this.token = this.lexer.next()
    }

    peek() {
        return this.token
    }
    at( type ) {
        return this.peek().type === type
    }
    advance() {
        const token = this.token
        this.token = this.lexer.next()
        return token
    }

    expect( type, msg ) {
        if ( this.at( type ) )
            return this.advance()

        const t = this.peek()
        throw new SyntaxError(
            `Parse error at pos ${t.pos}: expected ${msg || type} but got ${t.type} ('${t.value}')`
        )
    }

    // top level

    parseProgram() {
        const declarations = []
        while ( !this.at( TokenType.EOF ) ) {
            declarations.push( this.parseDeclaration() )
        }
        return Node.Program( declarations )
    }

    parseDeclaration() {
        const qualTok = this.expect( TokenType.IDENT, 'qualifier (uniform/const)' )
        if ( !QUALIFIERS.has( qualTok.value ) ) {
            throw new SyntaxError(
                `Parse error at pos ${qualTok.pos}: expected 'uniform' or 'const', got '${qualTok.value}'`
            )
        }
        const typeTok = this.expect( TokenType.IDENT, 'type name' )
        const nameTok = this.expect( TokenType.IDENT, 'declaration name' )
        this.expect( TokenType.EQUALS, "'='" )
        const init = this.parseExpression()
        return Node.Declaration( qualTok.value, typeTok.value, nameTok.value, init )
    }

    // expressions 

    parseExpression() {
        return this.parseAdditive()
    }

    parseAdditive() {
        let left = this.parseMultiplicative()
        while ( this.at( TokenType.PLUS ) || this.at( TokenType.MINUS ) ) {
            const op = this.advance().value
            const right = this.parseMultiplicative()
            left = Node.BinaryExpr( op, left, right )
        }
        return left
    }

    parseMultiplicative() {
        let left = this.parseUnary()
        while ( this.at( TokenType.STAR ) || this.at( TokenType.SLASH ) ) {
            const op = this.advance().value
            const right = this.parseUnary()
            left = Node.BinaryExpr( op, left, right )
        }
        return left
    }

    parseUnary() {
        if ( this.at( TokenType.PLUS ) || this.at( TokenType.MINUS ) ) {
            const op = this.advance().value
            return Node.UnaryExpr( op, this.parseUnary() )
        }
        return this.parsePostfix()
    }

    parsePostfix() {
        let expr = this.parsePrimary()
        while ( true ) {
            if ( this.at( TokenType.DOT ) ) {

                this.advance()
                const prop = this.expect( TokenType.IDENT, 'member name after .' )
                expr = Node.SwizzleExpr( expr, prop.value )

            } else if ( this.at( TokenType.LBRACKET ) ) {

                this.advance()
                const index = this.parseExpression()
                this.expect( TokenType.RBRACKET, "']'" )
                expr = Node.IndexExpr( expr, index )

            } else if ( this.at( TokenType.LPAREN ) ) {

                this.advance()
                const args = []
                if ( !this.at( TokenType.RPAREN ) ) {
                    args.push( this.parseExpression() )
                    while ( this.at( TokenType.COMMA ) ) {
                        this.advance()
                        args.push( this.parseExpression() )
                    }
                }
                this.expect( TokenType.RPAREN, "')'" )
                expr = Node.CallExpr( expr.name, args )

            } else {
                break
            }
        }
        return expr
    }

    parsePrimary() {
        const t = this.peek()
        if ( t.type === TokenType.NUMBER ) {
            this.advance()
            return Node.NumberLiteral( parseFloat( t.value ) )
        }
        if ( t.type === TokenType.IDENT ) {
            this.advance()
            return Node.Identifier( t.value )
        }
        if ( t.type === TokenType.LPAREN ) {
            this.advance()
            const expr = this.parseExpression()
            this.expect( TokenType.RPAREN, "')'" )
            return expr
        }
        throw new SyntaxError( `Parse error at pos ${t.pos}: unexpected token '${t.value ?? t.type}'` )
    }
}

export function parse( source ) {
    return new Parser( source ).parseProgram()
}
