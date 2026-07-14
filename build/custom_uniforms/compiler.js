import { parse } from "./parser.js"
import { Type } from "./compiler_type.js"
import { BuiltinFunctions, BuiltinOperators, constructor_identifier, constructor_number, constructor_convert } from "./compiler_functions.js"
import fs from 'fs'
import path from 'path'
import url from 'url'
import { inspect } from 'util'

const __dirname = path.dirname( url.fileURLToPath( import.meta.url ) )

const Variable = ( name, type, components ) => ( { name, type, components } )

const VARIABLES = new Map(
    JSON.parse( fs.readFileSync( path.join( __dirname, "variables.json" ) ) )
        .map( ( { name, type, components } ) => [name, Variable( name, Type( type ), components )] )
)

export function Compiler( program ) {
    const USER_VARIABLES = new Map

    function positioned( node, fn ) {
        try {
            return fn()
        } catch ( error ) {
            if ( error.pos !== undefined ) throw error

            const result = new Error( `Compile error at pos ${node.pos}: ${error.message}` )
            result.pos = node.pos
            result.cause = error
            throw result
        }
    }

    function expression( node ) {
        return positioned( node, () => {
            switch ( node.kind ) {
                case 'NumberLiteral': {
                    return constructor_number( node.value, Type( node.type ) )
                }
                case 'BoolLiteral': {
                    return constructor_number( node.value, Type.bool )
                }
                case 'Identifier': {
                    return constructor_identifier( node.name, VARIABLES, USER_VARIABLES )
                }
                case 'UnaryExpr': {
                    return BuiltinOperators[node.op + 'u']( expression( node.expr ) )
                }
                case 'BinaryExpr': {
                    return BuiltinOperators[node.op]( expression( node.left ), expression( node.right ) )
                }
                case 'TernaryExpr': {
                    return BuiltinOperators['?:'](
                        expression( node.condition ),
                        expression( node.if_true ),
                        expression( node.if_false )
                    )
                }
                case 'CallExpr': {
                    const fn = BuiltinFunctions[node.name]
                    if ( !fn ) throw new Error( `Unknown function '${node.name}'` )
                    return fn( ...node.args.map( expression ) )
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
        } )
    }

    function compileScalar( partial ) {
        if ( partial.value !== undefined )
            return `${partial}`
        return compileScalar( partial.components[0] )
    }

    function extractComponents( partial ) {
        function extract( component ) {
            const atom = component.components[0]
            return atom.literal ? atom.value : ""
        }

        if ( partial.type.scalar )
            return extract( partial )

        if ( partial.type.vector )
            return partial.components.map( extract )

        if ( partial.type.matrix ) {
            let matrix = []
            for ( let c = 0; c < partial.type.cols; c++ ) {
                let col = []
                for ( let r = 0; r < partial.type.rows; r++ ) {
                    let comp = partial.components[c * partial.type.rows + r]
                    col.push( extract( comp ) )
                }
                matrix.push( col )
            }
            return matrix
        }
    }

    function compile( declaration ) {
        return positioned( declaration, () => {
            const valueType = Type( declaration.valueType )
            const partial = constructor_convert( expression( declaration.expr ), valueType )
            const name = valueType.name
            const comps = partial.components.map( compileScalar )

            const user_component_literals = extractComponents( partial )
            USER_VARIABLES.set(
                declaration.name,
                Variable( declaration.name, valueType, user_component_literals )
            )

            // declaration
            let declqual = { const: "variable", uniform: "uniform" }[declaration.qualifier]
            let decltype = valueType.matrix ? `vec${valueType.rows}` : valueType.name
            let declname = declaration.name

            const prefix = `${declqual}.${decltype}.${declname}`

            // scalars
            if ( partial.type.scalar ) {
                return `${prefix} = ${comps[0]}`
            }

            // vectors
            if ( partial.type.vector ) {
                return `${prefix} = ${name}(${comps.join( ", " )})`
            }

            // matrices
            let c = []
            for ( let i = 0; i < partial.type.cols; i++ ) {
                let vec = comps.slice( partial.type.rows * i, partial.type.rows * ( i + 1 ) )
                let s = `vec${partial.type.rows}(${vec.join( ", " )})`
                c.push( `${prefix}_${i} = ${s}` )
            }

            return c.join( "\n" )
        } )
    }

    const declarations = program.declarations
    const results = []
    for ( let i = 0; i < declarations.length; i++ ) {
        const compiled = compile( declarations[i] )
        results.push( compiled )
    }

    return results
}

export function transpile( source ) {
    return Compiler( parse( source ) ).join( "\n" )
}

const source = `
const float sunLength = length(sunPosition);
uniform vec3 sunDir = sunPosition / sunLength;

const float moonLength = length(moonPosition);
uniform vec3 moonDir = moonPosition / moonLength;

const float upLength = length(mat3(gbufferModelView) * vec3(0, 1, 0));
uniform vec3 up = mat3(gbufferModelView) * vec3(0, 1, 0) / upLength;

const float dayLength = (12786.0 + 785.0) / 24000.0;
const float nightLength = 1. - dayLength;
const float normalizedTimeAligned = fract((float(worldTime) + 785.0) / 24000.0);

uniform vec2 screenSize        = vec2(viewWidth, viewHeight);
uniform vec2 screenSizeInverse = 1.0 / screenSize;

uniform vec2 lightPositionClip = (gbufferProjection * vec4(sunPosition, 1)).xy / -sunPosition.z;

uniform mat4 cu_gbufferModelView = gbufferModelView
uniform mat4 cu_gbufferModelViewInverse = gbufferModelViewInverse
uniform mat4 cu_gbufferProjection = gbufferProjection
uniform mat4 cu_gbufferProjectionInverse = gbufferProjectionInverse
uniform mat4 cu_gbufferPreviousModelView = gbufferPreviousModelView
uniform mat4 cu_gbufferPreviousProjection = gbufferPreviousProjection

uniform mat4 reproject = 
    mat4(
        .5,  0,  0, 0,
         0, .5,  0, 0,
         0,  0, .5, 0,
        .5, .5, .5, 1
    ) *                                                    // prev. clip -> prev. screen
    gbufferPreviousProjection * gbufferPreviousModelView * // prev. player -> prev. clip
    mat4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        cameraPosition - previousCameraPosition, 1
    ) *                                                    // player -> prev. player
    gbufferModelViewInverse * gbufferProjectionInverse *   // clip   -> player
    mat4(
         2,  0,  0, 0,
         0,  2,  0, 0,
         0,  0,  2, 0,
        -1, -1, -1, 1
    );                                                      // screen -> clip
` && `
// Normalized Positions
const float sunLength  = length(sunPosition);
uniform vec3 sunDir    = sunPosition / sunLength;

const float moonLength = length(moonPosition);
uniform vec3 moonDir   = moonPosition / moonLength;

const float upLength   = length(mat3(gbufferModelView) * vec3(0, 1, 0));
uniform vec3 up        = mat3(gbufferModelView) * vec3(0, 1, 0) / upLength;

/*
shadowLightPosition switches from the sun to the moon at 12786 ticks and back to the sun at 23215 ticks
normalizedTime goes from 0 at sunrise to 0.5 at sunset to 1 at the next sunrise
*/

// length of the day in normalizedTimeAligned
const float dayLength             = (12786.0 + 785.0) / 24000.0;
// length of the night in normalizedTimeAligned
const float nightLength           = 1. - dayLength;
// normalizedTimeAligned starts and ends at sunrise
const float normalizedTimeAligned = fract((worldTime + 785.0) / 24000.0);
// Modifying normalizedTimeAligned to be 0.5 at sunset, thus satifying the conditions
// Step 1: Selecting if its day or night
// Step 2: Normalizing for the day and bringing it to [0.0;0.5] to align sunset
// Step 3: Normalizing for the night and bringing it to [0.5;1.0] to align sunset for this part as well
uniform float normalizedTime = normalizedTimeAligned < dayLength
    ? (normalizedTimeAligned / dayLength) * 0.5
    : ((normalizedTimeAligned - dayLength) / nightLength) * 0.5 + 0.5;

// Texture Sizes
uniform vec2 screenSize        = vec2(viewWidth, viewHeight);
uniform vec2 screenSizeInverse = 1.0 / screenSize;

// Calling it lightPosition because moon and sun have the same screen space coordinates
uniform vec2 lightPositionClip = (gbufferProjection * vec4(sunPosition, 1)).xy / -sunPosition.z;

// Weather
uniform int   precipitation     = biome_precipitation
uniform float playerTemperature = temperature
uniform float rainPuddle        = smooth(float(biome_precipitation == 1 && temperature >= 0.15), 1.5) * wetness
`

if ( process.argv[1] && import.meta.url === url.pathToFileURL( process.argv[1] ).href ) {
    const ast = parse( source )

    console.log( '\n--- AST ---' )
    console.log( inspect( ast.declarations, { colors: true, depth: Infinity } ) )

    console.log( Compiler( ast ).join( "\n" ) )
}
