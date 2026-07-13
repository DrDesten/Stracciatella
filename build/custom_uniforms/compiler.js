import { parse } from "./parser.js"
import { Type } from "./compiler_type.js"
import { BuiltinFunctions, BuiltinOperators, constructor_identifier, constructor_number } from "./compiler_functions.js"
import fs from 'fs'
import path from 'path'
import url from 'url'
import { inspect } from 'util'

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

const Variable = ( name, type ) => ( { name, type } )

const VARIABLES = new Map(
    JSON.parse( fs.readFileSync( path.join( __dirname, "variables.json" ) ) )
        .map( ( { name, type } ) => [name, Variable( name, Type( type ) )] )
)

console.log( VARIABLES )

function Compiler( program ) {
    function expression( node ) {
        switch ( node.kind ) {
            case 'NumberLiteral': {
                return constructor_number( node.value )
            }
            case 'Identifier': {
                return constructor_identifier( node.name, VARIABLES )
            }
            case 'UnaryExpr': {
                return `${node.op}${stringify( node.argument )}`
            }
            case 'BinaryExpr': {
                return BuiltinOperators[node.op]( expression( node.left ), expression( node.right ) )
            }
            case 'CallExpr': {
                return BuiltinFunctions[node.name]( ...node.args.map( expression ) )
            }
            case 'SwizzleExpr': {
                return BuiltinOperators['swizzle']( expression( node.target ), node.swizzle )
            }
            case 'IndexExpr': {
                return BuiltinOperators['index']( expression( node.target ), node.index )
            }
            default:
                throw new Error( `Unknown node type: ${node.kind}` )
        }
    }

    function compile( partial ) {
        if ( partial.value ) {
            return partial.value
        }
        if ( partial.type.scalar ) {
            return compile( partial.components[0] )
        }
        if ( partial.type.vector ) {
            const name = partial.type.name
            const comps = partial.components.map( compile )
            return `${name}(${comps.join( ", " )})`
        }
    }

    const declarations = program.declarations
    const results = []
    for ( let i = 0; i < declarations.length; i++ ) {
        const partial = expression( declarations[i].expr )
        console.log( partial )
        const compiled = compile( partial )
        VARIABLES.set( declarations[i].name, Variable( declarations[i].name, partial.type ) )
        results.push( compiled )
    }

    return results
}


// Turns an expression AST back into GLSL-ish source, useful for sanity checks.
function stringify( node ) {
    switch ( node.kind ) {
        case 'NumberLiteral': return String( node.value )
        case 'Identifier': return node.name
        case 'UnaryExpr': return `${node.op}${stringify( node.argument )}`
        case 'BinaryExpr': return `(${stringify( node.left )} ${node.op} ${stringify( node.right )})`
        case 'CallExpr': return `${node.name}(${node.args.map( stringify ).join( ', ' )})`
        case 'SwizzleExpr': return `${stringify( node.target )}.${node.swizzle}`
        case 'IndexExpr': return `${stringify( node.target )}[${node.index}]`
        case 'Declaration':
            return `${node.qualifier} ${node.valueType} ${node.name} = ${stringify( node.expr )}`
        case 'Program': return node.declarations.map( stringify ).join( '\n' )
        default: throw new Error( `Unknown node type: ${node.kind}` )
    }
}

// ---------------------------------------------------------------------------
// Demo / self-test — runs only when this file is executed directly.
// ---------------------------------------------------------------------------

const source = `
uniform vec2 screenSize        = vec2(viewWidth, viewHeight)
uniform vec2 screenSizeInverse = 1.0 / screenSize

const   float sunLength  = length(sunPosition)
uniform vec3  sunDir     = sunPosition / sunLength
const   float moonLength = length(moonPosition.xyz)
uniform vec3  moonDir    = moonPosition.xyz / moonLength
const   float upLength   = sqrt(dot(gbufferModelView[1].xyz, gbufferModelView[1].xyz))
uniform vec3  up         = vec3(gbufferModelView[1].xyz / upLength)
`

const ast = parse( source )

console.log( '--- Round-tripped source ---' )
console.log( stringify( ast ) )

console.log( '\n--- AST (first declaration) ---' )
console.log( inspect( ast.declarations, { colors: true, depth: Infinity } ) )

console.log( Compiler( ast ) )