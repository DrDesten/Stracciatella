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
    FLOAT: 'FLOAT',
    INT: 'INT',
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
                while ( c = peek(), c === ' ' || c === '\t' || c === '\r' || c === '\n' || c == ';' )
                    advance()
            }
            function advanceSingleComment() {
                if ( peek() === '/' && peek( 1 ) === '/' ) while ( peek() != undefined && advance() != '\n' ) {}
            }
            function advanceMultiComment() {
                const start = index
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

                if ( level > 0 )
                    throw new SyntaxError( `Lexer error at pos ${start}: unterminated block comment` )
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
            if ( m = /^(\d+\.\d*|\.\d+?)([eE][+-]?\d+)?|\d+[eE][+-]?\d+/.exec( s ) ) {
                const token = Token( TokenType.FLOAT, m[0], index )
                advance( m[0].length )
                return token
            }
            if ( m = /^\d+/.exec( s ) ) {
                const token = Token( TokenType.INT, m[0], index )
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

            throw new SyntaxError( `Lexer error at pos ${index}: unexpected character '${c}'` )
        }
    }
}

const Node = {
    Program: ( declarations ) => ( { kind: 'Program', declarations } ),
    Declaration: ( qualifier, valueType, name, expr, pos ) => ( {
        kind: 'Declaration', qualifier, valueType, name, expr, pos
    } ),
    NumberLiteral: ( value, type, pos ) => ( { kind: 'NumberLiteral', value, type, pos } ),
    Identifier: ( name, pos ) => ( { kind: 'Identifier', name, pos } ),
    UnaryExpr: ( op, expr, pos ) => ( { kind: 'UnaryExpr', op, expr, pos } ),
    BinaryExpr: ( op, left, right, pos ) => ( { kind: 'BinaryExpr', op, left, right, pos } ),
    CallExpr: ( name, args, pos ) => ( { kind: 'CallExpr', name, args, pos } ),
    SwizzleExpr: ( target, swizzle, pos ) => ( { kind: 'SwizzleExpr', target, swizzle, pos } ),
    IndexExpr: ( target, index, pos ) => ( { kind: 'IndexExpr', target, index, pos } ),
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
        const qualt = this.expect( TokenType.IDENT, 'qualifier (uniform/const)' )
        if ( !QUALIFIERS.has( qualt.value ) ) {
            throw new SyntaxError(
                `Parse error at pos ${qualt.pos}: expected 'uniform' or 'const', got '${qualt.value}'`
            )
        }
        const typet = this.expect( TokenType.IDENT, 'type name' )
        const namet = this.expect( TokenType.IDENT, 'declaration name' )
        this.expect( TokenType.EQUALS, "'='" )
        const expr = this.parseExpression()
        return Node.Declaration( qualt.value, typet.value, namet.value, expr, qualt.pos )
    }

    // expressions 

    parseExpression() {
        return this.parseAdditive()
    }

    parseAdditive() {
        let left = this.parseMultiplicative()
        while ( this.at( TokenType.PLUS ) || this.at( TokenType.MINUS ) ) {
            const token = this.advance()
            const right = this.parseMultiplicative()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    parseMultiplicative() {
        let left = this.parseUnary()
        while ( this.at( TokenType.STAR ) || this.at( TokenType.SLASH ) ) {
            const token = this.advance()
            const right = this.parseUnary()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    parseUnary() {
        if ( this.at( TokenType.PLUS ) || this.at( TokenType.MINUS ) ) {
            const token = this.advance()
            return Node.UnaryExpr( token.value, this.parseUnary(), token.pos )
        }
        return this.parsePostfix()
    }

    parsePostfix() {
        let expr = this.parsePrimary()
        while ( true ) {
            if ( this.at( TokenType.DOT ) ) {

                const token = this.advance()
                const swizzle = this.expect( TokenType.IDENT, 'swizzle after .' )
                expr = Node.SwizzleExpr( expr, swizzle.value, token.pos )

            } else if ( this.at( TokenType.LBRACKET ) ) {

                const token = this.advance()
                const index = this.expect( TokenType.INT, 'index must be integer constant' )
                this.expect( TokenType.RBRACKET, "']'" )
                expr = Node.IndexExpr( expr, index.value, token.pos )

            } else if ( this.at( TokenType.LPAREN ) ) {

                const token = this.advance()
                if ( expr.kind !== 'Identifier' )
                    throw new SyntaxError( `Parse error at pos ${token.pos}: only identifiers can be called` )

                const args = []
                if ( !this.at( TokenType.RPAREN ) ) {
                    args.push( this.parseExpression() )
                    while ( this.at( TokenType.COMMA ) ) {
                        this.advance()
                        args.push( this.parseExpression() )
                    }
                }
                this.expect( TokenType.RPAREN, "')'" )
                expr = Node.CallExpr( expr.name, args, expr.pos )

            } else {
                break
            }
        }
        return expr
    }

    parsePrimary() {
        const t = this.peek()
        if ( t.type === TokenType.FLOAT ) {
            this.advance()
            return Node.NumberLiteral( +t.value, "float", t.pos )
        }
        if ( t.type === TokenType.INT ) {
            this.advance()
            return Node.NumberLiteral( +t.value, "int", t.pos )
        }
        if ( t.type === TokenType.IDENT ) {
            this.advance()
            return Node.Identifier( t.value, t.pos )
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