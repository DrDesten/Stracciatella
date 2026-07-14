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
    LESS: 'LESS',
    LESS_EQUAL: 'LESS_EQUAL',
    GREATER: 'GREATER',
    GREATER_EQUAL: 'GREATER_EQUAL',
    EQUAL_EQUAL: 'EQUAL_EQUAL',
    NOT_EQUAL: 'NOT_EQUAL',
    EQUALS: 'EQUALS',
    QUESTION: 'QUESTION',
    COLON: 'COLON',
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
    '<': TokenType.LESS,
    '>': TokenType.GREATER,
    '=': TokenType.EQUALS,
    '?': TokenType.QUESTION,
    ':': TokenType.COLON,
    '(': TokenType.LPAREN,
    ')': TokenType.RPAREN,
    '[': TokenType.LBRACKET,
    ']': TokenType.RBRACKET,
    '.': TokenType.DOT,
    ',': TokenType.COMMA,
}

const COMPOUND_TOKENS = {
    '<=': TokenType.LESS_EQUAL,
    '>=': TokenType.GREATER_EQUAL,
    '==': TokenType.EQUAL_EQUAL,
    '!=': TokenType.NOT_EQUAL,
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
            if ( COMPOUND_TOKENS[s.slice( 0, 2 )] ) {
                const value = s.slice( 0, 2 )
                const token = Token( COMPOUND_TOKENS[value], value, index )
                advance( 2 )
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
    BoolLiteral: ( value, pos ) => ( { kind: 'BoolLiteral', value, pos } ),
    Identifier: ( name, pos ) => ( { kind: 'Identifier', name, pos } ),
    UnaryExpr: ( op, expr, pos ) => ( { kind: 'UnaryExpr', op, expr, pos } ),
    BinaryExpr: ( op, left, right, pos ) => ( { kind: 'BinaryExpr', op, left, right, pos } ),
    TernaryExpr: ( condition, if_true, if_false, pos ) => ( {
        kind: 'TernaryExpr', condition, if_true, if_false, pos
    } ),
    CallExpr: ( name, args, pos ) => ( { kind: 'CallExpr', name, args, pos } ),
    SwizzleExpr: ( target, swizzle, pos ) => ( { kind: 'SwizzleExpr', target, swizzle, pos } ),
    IndexExpr: ( target, index, pos ) => ( { kind: 'IndexExpr', target, index, pos } ),
}

// ---------------------------------------------------------------------------
// Parser (recursive descent)
//
// Declaration    := ('uniform' | 'const') Ident Ident '=' Expression
// Expression     := Conditional
// Conditional    := Equality ('?' Expression ':' Conditional)?
// Equality       := Relational (('==' | '!=') Relational)*
// Relational     := Additive (('<' | '<=' | '>' | '>=') Additive)*
// Additive       := Multiplicative (('+' | '-') Multiplicative)*
// Multiplicative := Unary (('*' | '/') Unary)*
// Unary          := ('+' | '-') Unary | Postfix
// Postfix        := Primary ( '.' Ident | '[' Int ']' | '(' Args ')' )*
// Primary        := Number | Bool | Ident | '(' Expression ')'
// Args           := (Expression (',' Expression)*)?
// ---------------------------------------------------------------------------

const QUALIFIERS = new Set( ['uniform', 'const'] )

function Parser( source ) {
    const lexer = Lexer( source )
    let token = lexer.next()

    function peek() {
        return token
    }
    function at( type ) {
        return peek().type === type
    }
    function advance() {
        const previous = token
        token = lexer.next()
        return previous
    }
    function expect( type, msg ) {
        if ( at( type ) )
            return advance()

        const t = peek()
        throw new SyntaxError(
            `Parse error at pos ${t.pos}: expected ${msg || type} but got ${t.type} ('${t.value}')`
        )
    }

    function parseProgram() {
        const declarations = []
        while ( !at( TokenType.EOF ) )
            declarations.push( parseDeclaration() )
        return Node.Program( declarations )
    }

    function parseDeclaration() {
        const qualt = expect( TokenType.IDENT, 'qualifier (uniform/const)' )
        if ( !QUALIFIERS.has( qualt.value ) ) {
            throw new SyntaxError(
                `Parse error at pos ${qualt.pos}: expected 'uniform' or 'const', got '${qualt.value}'`
            )
        }

        const typet = expect( TokenType.IDENT, 'type name' )
        const namet = expect( TokenType.IDENT, 'declaration name' )
        expect( TokenType.EQUALS, "'='" )
        const expr = parseExpression()
        return Node.Declaration( qualt.value, typet.value, namet.value, expr, qualt.pos )
    }

    function parseExpression() {
        return parseConditional()
    }

    function parseConditional() {
        let condition = parseEquality()
        if ( !at( TokenType.QUESTION ) ) return condition

        const token = advance()
        const if_true = parseExpression()
        expect( TokenType.COLON, "':'" )
        const if_false = parseConditional()
        return Node.TernaryExpr( condition, if_true, if_false, token.pos )
    }

    function parseEquality() {
        let left = parseRelational()
        while ( at( TokenType.EQUAL_EQUAL ) || at( TokenType.NOT_EQUAL ) ) {
            const token = advance()
            const right = parseRelational()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    function parseRelational() {
        let left = parseAdditive()
        while (
            at( TokenType.LESS ) || at( TokenType.LESS_EQUAL ) ||
            at( TokenType.GREATER ) || at( TokenType.GREATER_EQUAL )
        ) {
            const token = advance()
            const right = parseAdditive()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    function parseAdditive() {
        let left = parseMultiplicative()
        while ( at( TokenType.PLUS ) || at( TokenType.MINUS ) ) {
            const token = advance()
            const right = parseMultiplicative()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    function parseMultiplicative() {
        let left = parseUnary()
        while ( at( TokenType.STAR ) || at( TokenType.SLASH ) ) {
            const token = advance()
            const right = parseUnary()
            left = Node.BinaryExpr( token.value, left, right, token.pos )
        }
        return left
    }

    function parseUnary() {
        if ( at( TokenType.PLUS ) || at( TokenType.MINUS ) ) {
            const token = advance()
            return Node.UnaryExpr( token.value, parseUnary(), token.pos )
        }
        return parsePostfix()
    }

    function parsePostfix() {
        let expr = parsePrimary()
        while ( true ) {
            if ( at( TokenType.DOT ) ) {

                const token = advance()
                const swizzle = expect( TokenType.IDENT, 'swizzle after .' )
                expr = Node.SwizzleExpr( expr, swizzle.value, token.pos )

            } else if ( at( TokenType.LBRACKET ) ) {

                const token = advance()
                const index = expect( TokenType.INT, 'index must be integer constant' )
                expect( TokenType.RBRACKET, "']'" )
                expr = Node.IndexExpr( expr, index.value, token.pos )

            } else if ( at( TokenType.LPAREN ) ) {

                const token = advance()
                if ( expr.kind !== 'Identifier' )
                    throw new SyntaxError( `Parse error at pos ${token.pos}: only identifiers can be called` )

                const args = []
                if ( !at( TokenType.RPAREN ) ) {
                    args.push( parseExpression() )
                    while ( at( TokenType.COMMA ) ) {
                        advance()
                        args.push( parseExpression() )
                    }
                }
                expect( TokenType.RPAREN, "')'" )
                expr = Node.CallExpr( expr.name, args, expr.pos )

            } else {
                break
            }
        }
        return expr
    }

    function parsePrimary() {
        const t = peek()
        if ( t.type === TokenType.FLOAT ) {
            advance()
            return Node.NumberLiteral( +t.value, "float", t.pos )
        }
        if ( t.type === TokenType.INT ) {
            advance()
            return Node.NumberLiteral( +t.value, "int", t.pos )
        }
        if ( t.type === TokenType.IDENT ) {
            advance()
            if ( t.value === 'true' || t.value === 'false' )
                return Node.BoolLiteral( t.value === 'true', t.pos )
            return Node.Identifier( t.value, t.pos )
        }
        if ( t.type === TokenType.LPAREN ) {
            advance()
            const expr = parseExpression()
            expect( TokenType.RPAREN, "')'" )
            return expr
        }
        throw new SyntaxError( `Parse error at pos ${t.pos}: unexpected token '${t.value ?? t.type}'` )
    }

    return { parseProgram }
}

export function parse( source ) {
    return Parser( source ).parseProgram()
}