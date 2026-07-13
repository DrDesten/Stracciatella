import { Type, Partial, Atom } from "./compiler_type.js"

function constructor_leaf( type, string ) {
    const atom = Atom( type, string )
    return Partial( atom.type, [atom] )
}

export function constructor_number( string ) {
    return constructor_leaf( Type( "float" ), string )
}
export function constructor_identifier( string, variable_set ) {
    if ( !variable_set.has( string ) )
        throw new Error( `Unknown identifier: ${string}` )

    const type = variable_set.get( string ).type

    if ( type.scalar ) {
        const atom = Atom( type, string )
        return Partial( atom.type, [atom] )
    }

    if ( type.vector ) {
        let underlying = Type( type.underlying )
        let components = []
        for ( let i = 0; i < type.components; i++ ) {
            const atom = Atom( underlying, string + '.' + 'xyzw'[i] )
            components.push( atom )
        }
        return Partial( type, components )
    }

    if ( type.matrix ) {
        let underlying = Type( type.underlying )
        let components = []

        for ( let c = 0; c < type.cols; c++ ) { // first: columns
            for ( let r = 0; r < type.rows; r++ ) { // then: rows

                // in shaders.properties, order is reversed compared to glsl
                let s = string + `[${r}].` + 'xyzw'[c]
                const atom = Atom( underlying, s )
                components.push( atom )

            }
        }

        return Partial( type, components )
    }

    throw new Error( `Unknown Type:`, type )
}

function operator_add( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        return constructor_leaf(
            a.type,
            `(${a.components[0]} + ${b.components[0]})`
        )
    }

    if ( a.type.scalar ) {
        let components = b.components.map( bc => operator_add( a, bc ) )
        return Partial( b.type, components )
    }

    if ( b.type.scalar ) {
        let components = a.components.map( ac => operator_add( ac, b ) )
        return Partial( a.type, components )
    }

    if ( a.type.vector && b.type.vector ) {
        let components = a.components.map( ( ac, i ) => operator_add( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '+' operands" )
}

function operator_sub( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        return constructor_leaf(
            a.type,
            `(${a.components[0]} - ${b.components[0]})`
        )
    }

    if ( a.type.scalar ) {
        let components = b.components.map( bc => operator_sub( a, bc ) )
        return Partial( b.type, components )
    }

    if ( b.type.scalar ) {
        let components = a.components.map( ac => operator_sub( ac, b ) )
        return Partial( a.type, components )
    }

    if ( a.type.vector && b.type.vector ) {
        let components = a.components.map( ( ac, i ) => operator_sub( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '-' operands" )
}

function operator_mul( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        return constructor_leaf(
            a.type,
            `(${a.components[0]} * ${b.components[0]})`
        )
    }

    if ( a.type.scalar ) {
        let components = b.components.map( bc => operator_mul( a, bc ) )
        return Partial( b.type, components )
    }

    if ( b.type.scalar ) {
        let components = a.components.map( ac => operator_mul( ac, b ) )
        return Partial( a.type, components )
    }

    if ( a.type.vector && b.type.vector ) {
        let components = a.components.map( ( ac, i ) => operator_mul( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '*' operands" )
}

function operator_div( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        return constructor_leaf(
            a.type,
            `(${a.components[0]} / ${b.components[0]})`
        )
    }

    if ( a.type.scalar ) {
        let components = b.components.map( bc => operator_div( a, bc ) )
        return Partial( b.type, components )
    }

    if ( b.type.scalar ) {
        let components = a.components.map( ac => operator_div( ac, b ) )
        return Partial( a.type, components )
    }

    if ( a.type.vector && b.type.vector ) {
        let components = a.components.map( ( ac, i ) => operator_div( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '/' operands" )
}

function operator_swizzle( x, swizzle ) {
    let indices = swizzle.split( "" ).map( c => ( {
        x: 0, y: 1, z: 2, w: 3,
        r: 0, g: 1, b: 2, a: 3,
        s: 0, t: 1, u: 2, v: 3,
    }[c] ) )
    let components = indices.map( i => x.components[i] )

    if ( x.type.matrix ) throw new Error( "Cannot swizzle matrix" )
    if ( indices.length > 4 ) throw new Error( "Swizzle to long" )
    if ( indices.some( i => i > x.components.length ) ) throw new Error( "Swizzle out of range" )

    return Partial( Type( "vec" + components.length ), components )
}

function operator_index( x, index ) {
    if ( x.type.scalar ) {
        if ( index !== 0 ) throw new Error( "Index out of range" )
        return x
    }

    if ( x.type.vector ) {
        if ( index > x.type.components ) throw new Error( "Index out of range" )
        return x.components[index]
    }

    if ( x.type.matrix ) {
        // in GLSL, matrices have column vectors
        if ( index > x.type.cols ) throw new Error( "Index out of range" )

        let components = []
        for ( let i = 0; i < x.type.rows; i++ ) {
            let idx = index * x.type.rows + i
            components.push( x.components[idx] )
        }

        return Partial( Type( "vec" + components.length ), components )
    }
}


function builtin_vec2( ...args ) {
    let components = args.flatMap( arg => arg.components )
    return Partial( Type( "vec2" ), components )
}
function builtin_vec3( ...args ) {
    let components = args.flatMap( arg => arg.components )
    return Partial( Type( "vec3" ), components )
}
function builtin_vec4( ...args ) {
    let components = args.flatMap( arg => arg.components )
    return Partial( Type( "vec4" ), components )
}

function builtin_sqrt( x ) {
    let components = x.components.map( c =>
        constructor_leaf( c.type, `sqrt(${c})` )
    )
    return Partial( x.type, components )
}
function builtin_dot( a, b ) {
    if ( a.type.components === b.type.components ) {
        let comps = []
        for ( let i = 0; i < a.type.components; i++ ) {
            let ac = a.components[i], bc = b.components[i]
            comps.push( `(${ac} * ${bc})` )
        }
        return constructor_leaf( Type( "float" ), "(" + comps.join( " + " ) + ")" )
    }
    throw new Error( "Unsupported 'dot()' operands" )
}
function builtin_length( x ) {
    return builtin_sqrt( builtin_dot( x, x ) )
}


export const BuiltinFunctions = {
    vec2: builtin_vec2,
    vec3: builtin_vec3,
    vec4: builtin_vec4,

    sqrt: builtin_sqrt,
    dot: builtin_dot,
    length: builtin_length,
}
export const BuiltinOperators = {
    '+': operator_add,
    '-': operator_sub,
    '*': operator_mul,
    '/': operator_div,

    'swizzle': operator_swizzle,
    'index': operator_index,
}