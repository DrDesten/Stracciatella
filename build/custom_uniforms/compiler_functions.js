import { Type, Partial, Atom } from "./compiler_type.js"

function constructor_leaf( type, string, literal = false ) {
    const atom = Atom( type, string, literal )
    return Partial( atom.type, [atom] )
}

export function constructor_number( value ) {
    return constructor_leaf( Type( "float" ), value, true )
}
export function constructor_identifier( string, variable_set ) {
    if ( !variable_set.has( string ) )
        throw new Error( `Unknown identifier: ${string}` )

    const type = variable_set.get( string ).type

    if ( type.scalar ) {
        return constructor_leaf(type, string)
    }

    if ( type.vector ) {
        let underlying = Type( type.underlying )
        let components = []
        for ( let i = 0; i < type.components; i++ ) {
            const leaf = constructor_leaf( underlying, string + '.' + 'xyzw'[i] )
            components.push( leaf )
        }
        return Partial( type, components )
    }

    if ( type.matrix ) {
        let underlying = Type( type.underlying )
        let components = []

        for ( let c = 0; c < type.cols; c++ ) { // first: columns
            for ( let r = 0; r < type.rows; r++ ) { // then: rows

                // in shaders.properties, order is reversed compared to glsl
                let s = string + `.${r}.${c}`
                const leaf = constructor_leaf( underlying, s )
                components.push( leaf )

            }
        }

        return Partial( type, components )
    }

    throw new Error( `Unknown Type:`, type )
}

function operator_add( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        let ac = a.components[0], bc = b.components[0]

        if (ac.literal && ac.value === 0) return b
        if (bc.literal && bc.value === 0) return a

        return constructor_leaf(a.type, `(${ac} + ${bc})`)
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
        if (a.type.components !== b.type.components)
            throw new Error( "Cannot broadcast different size vectors")

        let components = a.components.map( ( ac, i ) => operator_add( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '+' operands" )
}

function operator_sub( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        let ac = a.components[0], bc = b.components[0]

        if (ac.literal && ac.value === 0) return constructor_leaf(b.type,`(-${bc})`)
        if (bc.literal && bc.value === 0) return a

        return constructor_leaf(a.type,`(${ac} - ${bc})`)
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
        if (a.type.components !== b.type.components)
            throw new Error( "Cannot broadcast different size vectors")

        let components = a.components.map( ( ac, i ) => operator_sub( ac, b.components[i] ) )
        return Partial( a.type, components )
    }

    throw new Error( "Unsupported '-' operands" )
}

function operator_mul( a, b ) {
    if (a.type.scalar && b.type.scalar) {
        let ac = a.components[0], bc = b.components[0]

        if (ac.literal) {
            if (ac.value === 0) return a
            if (ac.value === 1) return b
        }
        if (bc.literal) {
            if (bc.value === 0) return b
            if (bc.value === 1) return a
        }

        return constructor_leaf(a.type, `(${ac} * ${bc})`)
    }

    if (a.type.scalar) {
        return Partial(
            b.type,
            b.components.map(bc => operator_mul(a, bc))
        );
    }

    if (b.type.scalar) {
        return Partial(
            a.type,
            a.components.map(ac => operator_mul(ac, b))
        );
    }

    if ( a.type.vector && b.type.vector ) {
        if (a.type.components !== b.type.components)
            throw new Error( "Cannot broadcast different size vectors")

        return Partial(
            a.type,
            a.components.map((ac, i) => operator_mul(ac, b.components[i]))
        );
    }

    // matrix * vector
    if (a.type.matrix && b.type.vector) {
        if (a.type.cols !== b.type.components)
            throw new Error("Matrix/vector dimension mismatch");

        let components = [];
        for (let r = 0; r < a.type.rows; r++) {
            let expr

            for (let c = 0; c < a.type.cols; c++) {
                const term = operator_mul(
                    a.components[c * a.type.rows + r],
                    b.components[c]
                );

                expr = expr
                    ? operator_add(expr, term)
                    : term;
            }

            components.push(expr);
        }

        return Partial(Type(`vec${a.type.rows}`), components);
    }

    // vector * matrix
    if (a.type.vector && b.type.matrix) {
        if (a.type.components !== b.type.rows)
            throw new Error("Vector/matrix dimension mismatch");

        let components = [];
        for (let c = 0; c < b.type.cols; ++c) {
            let expr

            for (let r = 0; r < b.type.rows; ++r) {
                const term = operator_mul(
                    a.components[r],
                    b.components[c * b.type.rows + r]
                );

                expr = expr
                    ? operator_add(expr, term)
                    : term;
            }

            components.push(expr);
        }

        return Partial(Type(`vec${b.type.cols}`), components);
    }

    // matrix * matrix
    if (a.type.matrix && b.type.matrix) {
        if (a.type.cols !== b.type.rows)
            throw new Error("Matrix/matrix dimension mismatch");

        const rows = a.type.rows;
        const cols = b.type.cols;
        const inner = a.type.cols;

        let components = []
        for (let c = 0; c < cols; ++c) {
            for (let r = 0; r < rows; ++r) {

                let expr
                for (let k = 0; k < inner; ++k) {
                    const term = operator_mul(
                        a.components[k * a.type.rows + r],
                        b.components[c * b.type.rows + k]
                    );

                    expr = expr
                        ? operator_add(expr, term)
                        : term;
                }

                components.push(expr);
            }
        }

        return Partial(Type(rows === cols ? `mat${rows}` : `mat${cols}x${rows}`), components);
    }

    throw new Error( "Unsupported '*' operands" )
}

function operator_div( a, b ) {
    if ( a.type.scalar && b.type.scalar ) {
        let ac = a.components[0], bc = b.components[0]

        if (ac.literal && ac.value === 0) return a
        if (bc.literal && bc.value === 1) return a

        return constructor_leaf(a.type, `(${ac} / ${bc})`)
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
        if (a.type.components !== b.type.components)
            throw new Error( "Cannot broadcast different size vectors" )

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

    if ( x.type.matrix ) 
        throw new Error( "Cannot swizzle matrix" )
    if ( indices.length > 4 ) 
        throw new Error( "Swizzle to long" )
    if ( indices.some( i => i > x.components.length ) ) 
        throw new Error( "Swizzle out of range" )

    if (components.length === 1) 
        return components[0]

    return Partial( Type( "vec" + components.length ), components )
}

function operator_index( x, index ) {
    if ( x.type.scalar ) {
        if ( index !== 0 ) throw new Error( "Index out of range" )
        return x
    }

    if ( x.type.vector ) {
        if ( index >= x.type.components ) throw new Error( "Index out of range" )
        return x.components[index]
    }

    if ( x.type.matrix ) {
        // in GLSL, matrices have column vectors
        if ( index >= x.type.cols ) throw new Error( "Index out of range" )

        let components = []
        for ( let i = 0; i < x.type.rows; i++ ) {
            let idx = index * x.type.rows + i
            components.push( x.components[idx] )
        }

        return Partial( Type( "vec" + components.length ), components )
    }

    throw new Error("Cannot index this type");
}


function builtin_vec2( ...args ) {
    let components = args.flatMap( arg => arg.components )
    if (components.length !== 2) throw new Error("vec2 constructor expects exactly 2 components");
    return Partial( Type( "vec2" ), components )
}
function builtin_vec3( ...args ) {
    let components = args.flatMap( arg => arg.components )
    if (components.length !== 3) throw new Error("vec3 constructor expects exactly 3 components");
    return Partial( Type( "vec3" ), components )
}
function builtin_vec4( ...args ) {
    let components = args.flatMap( arg => arg.components )
    if (components.length !== 4) throw new Error("vec4 constructor expects exactly 4 components");
    return Partial( Type( "vec4" ), components )
}

function builtin_matrix(typename, ...args) {
    const type = Type(typename);

    //
    // matN(s)
    //
    if (args.length === 1 && args[0].type.scalar) {
        const zero = constructor_number(0);
        const diag = args[0];

        let components = [];
        for (let c = 0; c < type.cols; c++)
            for (let r = 0; r < type.rows; r++) 
                components.push(r === c ? diag : zero);

        return Partial(type, components);
    }

    //
    // matX(matY)
    //
    if (args.length === 1 && args[0].type.matrix) {
        const src = args[0];
        const zero = constructor_number(0);
        const diag = constructor_number(1);

        let components = [];
        for (let c = 0; c < type.cols; c++) {
            for (let r = 0; r < type.rows; r++) {
                if (c < src.type.cols && r < src.type.rows) {
                    components.push(src.components[c * src.type.rows + r]);
                } else {
                    components.push(r === c ? diag : zero);
                }
            }
        }

        return Partial(type, components);
    }

    //
    // General constructor
    //
    let components = args.flatMap(x => x.components);
    if (components.length !== type.components)
        throw new Error(`${type.name} constructor expects ${type.components} scalar components`);

    return Partial(type, components);
}

function builtin_sqrt( x ) {
    let components = x.components.map( c =>
        constructor_leaf( c.type, `sqrt(${c})` )
    )
    return Partial( x.type, components )
}
function builtin_dot( a, b ) {
    if ( a.type.components !== b.type.components )
        throw new Error( "Unsupported 'dot()' operands" )

    let comps = []
    for ( let i = 0; i < a.type.components; i++ ) {
        let ac = a.components[i], bc = b.components[i]
        comps.push( operator_mul(ac, bc).components[0] )
    }
    return constructor_leaf( Type( "float" ), "(" + comps.join( " + " ) + ")" )    
}
function builtin_length( x ) {
    return builtin_sqrt( builtin_dot( x, x ) )
}
function builtin_normalize( x ) {
    return operator_div( x, builtin_length( x ) )
}


export const BuiltinFunctions = {
    vec2: builtin_vec2,
    vec3: builtin_vec3,
    vec4: builtin_vec4,

    mat2: (...a) => builtin_matrix("mat2", ...a),
    mat3: (...a) => builtin_matrix("mat3", ...a),
    mat4: (...a) => builtin_matrix("mat4", ...a),

    mat2x3: (...a) => builtin_matrix("mat2x3", ...a),
    mat2x4: (...a) => builtin_matrix("mat2x4", ...a),
    mat3x2: (...a) => builtin_matrix("mat3x2", ...a),
    mat3x4: (...a) => builtin_matrix("mat3x4", ...a),
    mat4x2: (...a) => builtin_matrix("mat4x2", ...a),
    mat4x3: (...a) => builtin_matrix("mat4x3", ...a),

    sqrt: builtin_sqrt,
    dot: builtin_dot,
    length: builtin_length,
    normalize: builtin_normalize,
}
export const BuiltinOperators = {
    '+': operator_add,
    '-': operator_sub,
    '*': operator_mul,
    '/': operator_div,

    'swizzle': operator_swizzle,
    'index': operator_index,
}