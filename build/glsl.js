// Helpers
function o( type, string ) {
    return { type, string, toString: () => string }
}
function unwrap( func ) {
    return ( ...args ) => func( ...args ).string
}

function dim( array ) {
    if ( typeof array === "number" ) return [0]

    let typecheck = new Set( array.map( x => typeof x ) )
    if ( typecheck.size !== 1 )
        throw new Error( `Inhomogenious array of types ${[...typecheck.values()].join( ", " )}` )

    let type = typecheck.values().next().value
    if ( type === "number" ) return [array.length]
    if ( type === "object" ) return [array.length, ...dim( array[0] )]

    throw new Error( `Invalid array type ${type}` )
}

// Expressions

function float( x ) {
    return o( "float", `float(${x})` )
}

function vector( arr ) {
    const [d] = dim( arr )
    switch ( arr.length ) {
        case 2: return o( "vec2", `vec2(${arr.join( ", " )})` )
        case 3: return o( "vec3", `vec3(${arr.join( ", " )})` )
        case 4: return o( "vec3", `vec4(${arr.join( ", " )})` )
    }
    throw new Error( "Invalid vector length" )
}

function array( arr ) {
    const [d] = dim( arr )
    const t = arrayauto( arr[0] ).type
    return o( `${t}[${d}]`, `${t}[${d}](${arr.map( x => arrayauto( x ) )})` )
}

function arrayauto( arr ) {
    const d = dim( arr )
    if ( d.length === 0 )
        return float( arr )
    if ( d.length === 1 && d[0] >= 2 && d[0] <= 4 )
        return vector( arr )
    return array( arr )
}

// Statements

function constant( identifier, expr ) {
    return o( undefined, `const ${expr.type} ${identifier} = ${expr};` )
}

export const GLSL = {
    float: float,
    vector: vector,
    array: array,

    constant: constant,
}