import { Type, Partial, Atom, Precedence, type_underlying, type_from, type_promote_underlying, type_promote, type_shape_eq } from "./compiler_type.js"

function constructor_leaf( type, string, literal = false, precedence = Precedence.PRIMARY ) {
    const atom = Atom( type, string, literal, precedence )
    return Partial( atom.type, [atom] )
}

function constructor_constant( type, value ) {
    if ( !Number.isFinite( value ) && !type.boolean )
        throw new Error( "Constant expression produced a non-finite value" )

    if ( Object.is( value, -0 ) ) value = 0
    return constructor_leaf( type, value, true )
}

function scalar_atom( x ) {
    if ( !x.type.scalar )
        throw new Error( "Expected scalar expression" )
    return x.components[0]
}

function render_operand( x, precedence, right = false ) {
    const atom = scalar_atom( x )
    const parens = atom.precedence < precedence || right && atom.precedence === precedence
    return parens ? `(${atom})` : `${atom}`
}

function convert_constant( type, value ) {
    if ( type.boolean ) return !!value
    if ( type.name === 'uint' ) return Math.trunc( value ) >>> 0
    if ( type.integral ) return Math.trunc( value )
    return value
}

function convert_scalar( x, type ) {
    if ( !x.type.scalar || !type.scalar )
        throw new Error( "Scalar conversion requires scalar types" )

    if ( x.type === type ) return x
    if ( x.type.boolean )
        return operator_ternary( x,
            constructor_constant( type, 1 ),
            constructor_constant( type, 0 )
        )
    if ( type.boolean )
        throw new Error( `Cannot convert '${x.type}' to '${type}'` )

    const atom = scalar_atom( x )
    if ( atom.literal )
        return constructor_constant( type, convert_constant( type, atom.value ) )

    // shaders.properties has no cast function. Adding a floating zero is the
    // smallest expression which preserves a GLSL int -> float conversion.
    if ( x.type.integral && type.floating ) {
        const value = `${render_operand( x, Precedence.ADDITIVE )} + 0.0`
        return constructor_leaf( type, value, false, Precedence.ADDITIVE )
    }

    if ( x.type.floating && type.floating )
        return constructor_leaf( type, `${atom}`, false, atom.precedence )

    throw new Error( `Cannot lower conversion from '${x.type}' to '${type}'` )
}

function promote_scalar( x, type ) {
    if ( x.type === type ) return x
    if ( x.type.boolean || type.boolean )
        throw new Error( `Cannot promote '${x.type}' to '${type}'` )

    const atom = scalar_atom( x )
    if ( atom.literal )
        return constructor_constant( type, convert_constant( type, atom.value ) )

    return constructor_leaf( type, `${atom}`, false, atom.precedence )
}

export function constructor_convert( x, type ) {
    // same type
    if (x.type.name === type.name) 
        return x
    // promote to scalar
    if (type.scalar) {
        if (x.type.scalar) return convert_scalar(x, type)
        else throw new Error(`Cannot downcast non-scalar '${x.type.name}' to scalar '${type.name}'`)
    }
    // promote scalar to non-scalar
    if (x.type.scalar) {
        const underlying = type_underlying(type)
        const components = Array.from(
            {length:type.components}, 
            () => convert_scalar(x, underlying)
        )
        return Partial(type, components)
    }
    // promote non-scalar to non-scalar
    if (type_shape_eq(x.type, type)) {
        const underlying = type_underlying(type)
        const components = x.components.map(c => convert_scalar(c, underlying))
        return Partial(type, components)
    }
    throw new Error(`Illegal conversion from '${x.type.name}' to '${type.name}'`)
}

/* export function constructor_convert( x, type ) {
    if ( x.type.scalar || type.scalar ) {
        if ( !x.type.scalar || !type.scalar )
            throw new Error( `Cannot convert '${x.type}' to '${type}'` )
        return convert_scalar( x, type )
    }

    const same_shape =
        x.type.vector && type.vector && x.type.components === type.components ||
        x.type.matrix && type.matrix && x.type.rows === type.rows && x.type.cols === type.cols

    if ( !same_shape )
        throw new Error( `Cannot convert '${x.type}' to '${type}'` )

    const component_type = type_underlying( type )
    return Partial( type, x.components.map( c => convert_scalar( c, component_type ) ) )
} */

function fold_unary( type, x, comptime_fn ) {
    const atom = scalar_atom( x )
    if ( !atom.literal ) return
    return constructor_constant( type, convert_constant( type, comptime_fn( atom.value ) ) )
}

function fold_binary( type, a, b, comptime_fn ) {
    const ac = scalar_atom( a ), bc = scalar_atom( b )
    if ( !ac.literal || !bc.literal ) return
    return constructor_constant( type, convert_constant( type, comptime_fn( ac.value, bc.value ) ) )
}

function partial_shape( shape, components ) {
    if ( shape.type.scalar ) return components[0]
    return Partial( type_from( shape.type, components[0].type ), components )
}

function same_component_shape( a, b ) {
    return a.type.vector && b.type.vector && a.type.components === b.type.components ||
        a.type.matrix && b.type.matrix && a.type.rows === b.type.rows && a.type.cols === b.type.cols
}

function operator_componentwise( a, b, fn, symbol ) {
    if ( a.type.scalar && b.type.scalar )
        return fn( a, b )

    if ( a.type.scalar ) {
        const components = b.components.map( bc => fn( a, bc ) )
        return partial_shape( b, components )
    }

    if ( b.type.scalar ) {
        const components = a.components.map( ac => fn( ac, b ) )
        return partial_shape( a, components )
    }

    if ( same_component_shape( a, b ) ) {
        const components = a.components.map( ( ac, i ) => fn( ac, b.components[i] ) )
        return partial_shape( a, components )
    }

    throw new Error( `Unsupported '${symbol}' operands '${a.type}' and '${b.type}'` )
}

function binary_scalar( symbol, precedence, a, b, fold ) {
    const type = type_promote_underlying( a.type, b.type )
    a = promote_scalar( a, type )
    b = promote_scalar( b, type )

    const folded = fold_binary( type, a, b, fold )
    if ( folded ) return folded

    const value = `${render_operand( a, precedence )} ${symbol} ${render_operand( b, precedence, true )}`
    return constructor_leaf( type, value, false, precedence )
}

export function constructor_number( value, type ) {
    return constructor_constant( type, convert_constant( type, value ) )
}

export function constructor_identifier( string, builtin_varset, user_varset ) {
    if ( !builtin_varset.has( string ) && !user_varset.has( string ) )
        throw new Error( `Unknown identifier: ${string}` )

    const user_var = !builtin_varset.has( string )
    const variable = user_var ? user_varset.get( string ) : builtin_varset.get( string )
    const type = variable.type
    const comp_override = variable.components

    if ( type.scalar ) {
        if ( typeof comp_override === 'number' || typeof comp_override === 'boolean' )
            return constructor_number( comp_override, type )

        return constructor_leaf( type, string )
    }

    if ( type.vector ) {
        let underlying = type_underlying( type )
        let components = []
        for ( let i = 0; i < type.components; i++ ) {
            const leaf = typeof comp_override?.[i] === 'number' || typeof comp_override?.[i] === 'boolean'
                ? constructor_number( comp_override[i], underlying )
                : constructor_leaf( underlying, string + '.' + 'xyzw'[i] )
            components.push( leaf )
        }
        return Partial( type, components )
    }

    if ( type.matrix ) {
        let underlying = type_underlying( type )
        let components = []

        for ( let c = 0; c < type.cols; c++ ) { // first: columns
            for ( let r = 0; r < type.rows; r++ ) { // then: rows

                if ( typeof comp_override?.[c]?.[r] === 'number' ) {
                    const num = constructor_number( comp_override[c][r], underlying )
                    components.push( num )
                    continue
                }

                let s
                if ( user_var ) {
                    // if user variable, its split into vectors
                    s = string + `_${c}.` + "xyzw"[r]
                } else {
                    // in shaders.properties, order is reversed compared to glsl
                    s = string + `.${c}.${r}`
                }

                components.push( constructor_leaf( underlying, s ) )
            }
        }

        return Partial( type, components )
    }

    throw new Error( `Unknown Type: ${type}` )
}

function operator_neg( x ) {
    if ( x.type.boolean )
        throw new Error( "Unary '-' requires a numeric operand" )

    if ( !x.type.scalar ) {
        const components = x.components.map( operator_neg )
        return Partial( x.type, components )
    }

    const folded = fold_unary( x.type, x, value => -value )
    if ( folded ) return folded

    return constructor_leaf(
        x.type,
        `-${render_operand( x, Precedence.UNARY, true )}`,
        false,
        Precedence.UNARY
    )
}

function operator_pos( x ) {
    if ( x.type.boolean )
        throw new Error( "Unary '+' requires a numeric operand" )
    return x
}

function scalar_add( a, b ) {
    const type = type_promote_underlying( a.type, b.type )
    a = promote_scalar( a, type )
    b = promote_scalar( b, type )

    const ac = scalar_atom( a ), bc = scalar_atom( b )
    const folded = fold_binary( type, a, b, ( a, b ) => a + b )
    if ( folded ) return folded

    if ( ac.literal && ac.value === 0 ) return b
    if ( bc.literal && bc.value === 0 ) return a

    return binary_scalar( '+', Precedence.ADDITIVE, a, b, ( a, b ) => a + b )
}

function operator_add( a, b ) {
    return operator_componentwise( a, b, scalar_add, '+' )
}

function scalar_sub( a, b ) {
    const type = type_promote_underlying( a.type, b.type )
    a = promote_scalar( a, type )
    b = promote_scalar( b, type )

    const ac = scalar_atom( a ), bc = scalar_atom( b )
    const folded = fold_binary( type, a, b, ( a, b ) => a - b )
    if ( folded ) return folded

    if ( ac.literal && ac.value === 0 ) return operator_neg( b )
    if ( bc.literal && bc.value === 0 ) return a

    return binary_scalar( '-', Precedence.ADDITIVE, a, b, ( a, b ) => a - b )
}

function operator_sub( a, b ) {
    return operator_componentwise( a, b, scalar_sub, '-' )
}

function scalar_mul( a, b ) {
    const type = type_promote_underlying( a.type, b.type )
    a = promote_scalar( a, type )
    b = promote_scalar( b, type )

    const ac = scalar_atom( a ), bc = scalar_atom( b )
    const folded = fold_binary( type, a, b, ( a, b ) => a * b )
    if ( folded ) return folded

    if ( ac.literal ) {
        if ( ac.value === 0 ) return a
        if ( ac.value === 1 ) return b
        if ( ac.value === -1 ) return operator_neg( b )
    }
    if ( bc.literal ) {
        if ( bc.value === 0 ) return b
        if ( bc.value === 1 ) return a
        if ( bc.value === -1 ) return operator_neg( a )
    }

    return binary_scalar( '*', Precedence.MULTIPLICATIVE, a, b, ( a, b ) => a * b )
}

function operator_mul( a, b ) {
    if ( a.type.scalar || b.type.scalar || a.type.vector && b.type.vector )
        return operator_componentwise( a, b, scalar_mul, '*' )

    // matrix * vector
    if ( a.type.matrix && b.type.vector ) {
        if ( a.type.cols !== b.type.components )
            throw new Error( "Matrix/vector dimension mismatch" )

        let components = []
        for ( let r = 0; r < a.type.rows; r++ ) {
            let expr

            for ( let c = 0; c < a.type.cols; c++ ) {
                const term = operator_mul(
                    a.components[c * a.type.rows + r],
                    b.components[c]
                )

                expr = expr ? operator_add( expr, term ) : term
            }

            components.push( expr )
        }

        return Partial( type_from( [a.type.rows], components[0].type ), components )
    }

    // vector * matrix
    if ( a.type.vector && b.type.matrix ) {
        if ( a.type.components !== b.type.rows )
            throw new Error( "Vector/matrix dimension mismatch" )

        let components = []
        for ( let c = 0; c < b.type.cols; ++c ) {
            let expr

            for ( let r = 0; r < b.type.rows; ++r ) {
                const term = operator_mul(
                    a.components[r],
                    b.components[c * b.type.rows + r]
                )

                expr = expr ? operator_add( expr, term ) : term
            }

            components.push( expr )
        }

        return Partial( type_from( [b.type.cols], components[0].type ), components )
    }

    // matrix * matrix
    if ( a.type.matrix && b.type.matrix ) {
        if ( a.type.cols !== b.type.rows )
            throw new Error( "Matrix/matrix dimension mismatch" )

        const rows = a.type.rows
        const cols = b.type.cols
        const inner = a.type.cols

        let components = []
        for ( let c = 0; c < cols; ++c ) {
            for ( let r = 0; r < rows; ++r ) {

                let expr
                for ( let k = 0; k < inner; ++k ) {
                    const term = operator_mul(
                        a.components[k * a.type.rows + r],
                        b.components[c * b.type.rows + k]
                    )

                    expr = expr ? operator_add( expr, term ) : term
                }

                components.push( expr )
            }
        }

        return Partial( type_from( [cols, rows], components[0].type ), components )
    }

    throw new Error( "Unsupported '*' operands" )
}

function scalar_div( a, b ) {
    const type = type_promote_underlying( a.type, b.type )
    a = promote_scalar( a, type )
    b = promote_scalar( b, type )

    const ac = scalar_atom( a ), bc = scalar_atom( b )
    const divide = type.integral
        ? ( a, b ) => Math.trunc( a / b )
        : ( a, b ) => a / b

    const folded = fold_binary( type, a, b, divide )
    if ( folded ) return folded

    if ( ac.literal && ac.value === 0 ) return a
    if ( bc.literal && bc.value === 1 ) return a
    if ( bc.literal && bc.value === -1 ) return operator_neg( a )

    return binary_scalar( '/', Precedence.MULTIPLICATIVE, a, b, divide )
}

function operator_div( a, b ) {
    return operator_componentwise( a, b, scalar_div, '/' )
}

function operator_compare( operator, a, b ) {
    if ( !a.type.scalar || !b.type.scalar )
        throw new Error( `Comparison '${operator}' only supports scalar operands` )

    const equality = operator === '==' || operator === '!='
    if ( a.type.boolean || b.type.boolean ) {
        if ( !equality || !a.type.boolean || !b.type.boolean )
            throw new Error( `Unsupported '${operator}' operands '${a.type}' and '${b.type}'` )
    } else {
        const type = type_promote_underlying( a.type, b.type )
        a = promote_scalar( a, type )
        b = promote_scalar( b, type )
    }

    const fn = {
        '<': ( a, b ) => a < b,
        '<=': ( a, b ) => a <= b,
        '>': ( a, b ) => a > b,
        '>=': ( a, b ) => a >= b,
        '==': ( a, b ) => a === b,
        '!=': ( a, b ) => a !== b,
    }[operator]

    const folded = fold_binary( Type.bool, a, b, fn )
    if ( folded ) return folded

    const value = `${render_operand( a, Precedence.COMPARISON )} ${operator} ${render_operand( b, Precedence.COMPARISON, true )}`
    return constructor_leaf( Type.bool, value, false, Precedence.COMPARISON )
}

function operator_logical( operator, a, b ) {
    if ( !a.type.scalar || !b.type.scalar || !a.type.boolean || !b.type.boolean )
        throw new Error( `Logical '${operator}' requires scalar bool operands` )

    const prec = { '&&': Precedence.LOGICAL_AND, '||': Precedence.LOGICAL_OR }[operator]
    const fn = { '&&': ( a, b ) => a && b, '||': ( a, b ) => a || b }[operator]

    const folded = fold_binary( Type.bool, a, b, fn )
    if ( folded ) return folded

    const ac = scalar_atom( a )
    const bc = scalar_atom( b )

    if ( operator === '&&' ) {
        if ( ac.literal ) return ac.value ? b : a
        if ( bc.literal ) return bc.value ? a : b
    }

    if ( operator === '||' ) {
        if ( ac.literal ) return ac.value ? a : b
        if ( bc.literal ) return bc.value ? b : a
    }

    const value =
        `${render_operand( a, prec )} ${operator} ` +
        `${render_operand( b, prec )}`

    return constructor_leaf( Type.bool, value, false, prec )
}

function common_branch_type( a, b ) {
    if ( a.scalar && b.scalar )
        return type_promote_underlying( a, b )

    const same_shape =
        a.vector && b.vector && a.components === b.components ||
        a.matrix && b.matrix && a.rows === b.rows && a.cols === b.cols

    if ( !same_shape )
        throw new Error( `Ternary branches have incompatible types '${a}' and '${b}'` )

    return type_from( a, type_promote_underlying( a, b ) )
}

function operator_ternary( condition, if_true, if_false ) {
    if ( !condition.type.scalar || !condition.type.boolean )
        throw new Error( "Ternary condition must be a scalar bool" )

    const type = common_branch_type( if_true.type, if_false.type )
    if_true = constructor_convert( if_true, type )
    if_false = constructor_convert( if_false, type )

    const condition_atom = scalar_atom( condition )
    if ( condition_atom.literal )
        return condition_atom.value ? if_true : if_false

    function select_scalar( a, b ) {
        const value = `if(${condition_atom}, ${scalar_atom( a )}, ${scalar_atom( b )})`
        return constructor_leaf( a.type, value, false, Precedence.CALL )
    }

    if ( type.scalar )
        return select_scalar( if_true, if_false )

    const components = if_true.components.map( ( c, i ) => select_scalar( c, if_false.components[i] ) )
    return Partial( type, components )
}

function operator_swizzle( x, swizzle ) {
    let indices = swizzle.split( "" ).map( c => ( {
        x: 0, y: 1, z: 2, w: 3,
        r: 0, g: 1, b: 2, a: 3,
        s: 0, t: 1, p: 2, q: 3,
    }[c] ) )

    if ( x.type.matrix )
        throw new Error( "Cannot swizzle matrix" )
    if ( indices.length > 4 )
        throw new Error( "Swizzle too long" )
    if ( indices.some( i => i === undefined ) )
        throw new Error( `Invalid swizzle '${swizzle}'` )
    if ( indices.some( i => i >= x.components.length ) )
        throw new Error( "Swizzle out of range" )

    let components = indices.map( i => x.components[i] )

    if ( components.length === 1 )
        return components[0]

    return Partial( type_from( Type( "vec" + components.length ), components[0].type ), components )
}

function operator_index( x, index ) {
    index = +index

    if ( x.type.scalar ) {
        if ( index !== 0 ) throw new Error( "Index out of range" )
        return x
    }

    if ( x.type.vector ) {
        if ( index < 0 || index >= x.type.components ) throw new Error( "Index out of range" )
        return x.components[index]
    }

    if ( x.type.matrix ) {
        // in GLSL, matrices have column vectors
        if ( index < 0 || index >= x.type.cols ) throw new Error( "Index out of range" )

        let components = []
        for ( let i = 0; i < x.type.rows; i++ ) {
            let idx = index * x.type.rows + i
            components.push( x.components[idx] )
        }

        return Partial( type_from( Type( "vec" + components.length ), components[0].type ), components )
    }

    throw new Error( "Cannot index this type" )
}

function builtin_scalar( typename, ...args ) {
    let components = args.flatMap( arg => arg.components )
    if ( components.length !== 1 )
        throw new Error( `${typename} constructor expects a single argument` )
    return convert_scalar( components[0], Type( typename ) )
}

function builtin_vector( typename, ...args ) {
    const type = Type( typename )
    let components = args.flatMap( arg => arg.components )

    if ( components.length === 1 )
        components = Array( type.components ).fill( components[0] )

    if ( components.length !== type.components )
        throw new Error( `${typename} constructor expects exactly ${type.components} components` )

    const component_type = type_underlying( type )
    return Partial( type, components.map( c => convert_scalar( c, component_type ) ) )
}

function builtin_matrix( typename, ...args ) {
    const type = Type( typename )
    const underlying = type_underlying( type )

    //
    // matN(s)
    //
    if ( args.length === 1 && args[0].type.scalar ) {
        const zero = constructor_number( 0, underlying )
        const diag = convert_scalar( args[0], underlying )

        let components = []
        for ( let c = 0; c < type.cols; c++ )
            for ( let r = 0; r < type.rows; r++ )
                components.push( r === c ? diag : zero )

        return Partial( type, components )
    }

    //
    // matX(matY)
    //
    if ( args.length === 1 && args[0].type.matrix ) {
        const src = args[0]
        const zero = constructor_number( 0, underlying )
        const diag = constructor_number( 1, underlying )

        let components = []
        for ( let c = 0; c < type.cols; c++ ) {
            for ( let r = 0; r < type.rows; r++ ) {
                if ( c < src.type.cols && r < src.type.rows ) {
                    components.push( convert_scalar( src.components[c * src.type.rows + r], underlying ) )
                } else {
                    components.push( r === c ? diag : zero )
                }
            }
        }

        return Partial( type, components )
    }

    //
    // General constructor
    //
    let components = args.flatMap( x => x.components )
    if ( components.length !== type.components )
        throw new Error( `${type.name} constructor expects ${type.components} scalar components` )

    return Partial( type, components.map( c => convert_scalar( c, underlying ) ) )
}

function util_promote_equalize(partials) {
    const type = type_promote(...partials.map(x => x.type))
    const promoted = partials.map(x => constructor_convert(x, type))
    return [type, promoted]
}


function builtin_distributed_multi_scalar(scalar_fn, comptime_fn) {
    let scalar = typeof scalar_fn === 'string'
        ? function(...args) {
            return constructor_leaf( 
                args[0].type, 
                `${scalar_fn}(${args.map(scalar_atom).join(", ")})`, 
                false, Precedence.CALL 
            )
        }
        : scalar_fn 

    return function(...args) {
        const [type, promoted] = util_promote_equalize(args)
        return type.scalar
            ? scalar(...promoted)
            : Partial(type, Array.from(
                {length:type.components},
                (_,i) => scalar(...promoted.map(x => x.components[i]))
            ))
    }
}

function builtin_distributed_scalar(name, comptime_fn, require_floating = false) {
    const scalar_fn = comptime_fn
        ? function(c) {
            const folded = fold_unary( c.type, c, comptime_fn )
            if ( folded ) return folded
            return constructor_leaf( c.type, `${name}(${scalar_atom( c )})`, false, Precedence.CALL )
        }
        : function(c) {
            return constructor_leaf( c.type, `${name}(${scalar_atom( c )})`, false, Precedence.CALL )
        }

    return function(x) {
        return x.type.scalar 
            ? scalar_fn(x)
            : Partial(x.type, x.components.map(scalar_fn))
    }
}

let builtin_smooth_idx = 0
function builtin_smooth_scalar(x, smooth_in, smooth_out) {
    const a = [
        builtin_smooth_idx++, 
        scalar_atom(x), 
        scalar_atom(smooth_in), 
        ...(smooth_out ? [scalar_atom(smooth_out)] : [])
    ]
    const s = `smooth(${a.join(", ")})`
    return constructor_leaf( x.type, s, false, Precedence.CALL )
}/* 
function builtin_smooth( ...args ) {
    if ( args.length != 2 && args.length != 3 )
        throw new Error( `smooth() requires two or three parameters` )

    let [x, smooth_in, smooth_out] = args
    if ( !smooth_in.type.scalar )
        throw new Error( `smooth() requires smoothness to be a scalar` )
    if ( !scalar_atom( smooth_in ).literal )
        throw new Error( `smooth() requires smoothness to be a constant literal` )

    function scalar_smooth( x, smooth ) {
        const s = `smooth(${builtin_smooth_idx++}, ${scalar_atom( x )}, ${scalar_atom( smooth )})`
        return constructor_leaf( x.type, s, false, Precedence.CALL )
    }

    if ( x.type.scalar ) return scalar_smooth( x, smooth_in )
    return Partial( x.type, x.components.map( c => scalar_smooth( c, smooth_in ) ) )
} */

const builtin_sqrt = builtin_distributed_scalar("sqrt", Math.sqrt, true)
const builtin_sin = builtin_distributed_scalar("sin", Math.sin, true)
const builtin_cos = builtin_distributed_scalar("cos", Math.cos, true)
const builtin_tan = builtin_distributed_scalar("tan", Math.tan, true)

const builtin_abs = builtin_distributed_scalar("abs", Math.abs, true)
const builtin_floor = builtin_distributed_scalar("floor", Math.floor, true)
const builtin_ceil = builtin_distributed_scalar("ceil", Math.ceil, true)
const builtin_round = builtin_distributed_scalar("round", Math.round, true)
const builtin_fract = builtin_distributed_scalar("frac", x => x - Math.floor( x ), true)

const builtin_min = builtin_distributed_multi_scalar("min")
const builtin_max = builtin_distributed_multi_scalar("max")
const builtin_clamp = builtin_distributed_multi_scalar("clamp")

const builtin_smooth = builtin_distributed_multi_scalar(builtin_smooth_scalar)

const builtin_pow = builtin_distributed_multi_scalar("pow")

function builtin_dot( a, b ) {
    if ( !a.type.vector || !b.type.vector || a.type.components !== b.type.components )
        throw new Error( "Unsupported 'dot()' operands" )
    if ( !a.type.floating || !b.type.floating )
        throw new Error( "dot() requires floating-point vectors" )

    let result
    for ( let i = 0; i < a.type.components; i++ ) {
        const term = operator_mul( a.components[i], b.components[i] )
        result = result ? operator_add( result, term ) : term
    }
    return result
}
function builtin_length( x ) {
    return builtin_sqrt( builtin_dot( x, x ) )
}
function builtin_normalize( x ) {
    return operator_div( x, builtin_length( x ) )
}

export const BuiltinFunctions = {
    float: ( ...a ) => builtin_scalar( 'float', ...a ),

    vec2: ( ...a ) => builtin_vector( 'vec2', ...a ),
    vec3: ( ...a ) => builtin_vector( 'vec3', ...a ),
    vec4: ( ...a ) => builtin_vector( 'vec4', ...a ),

    mat2: ( ...a ) => builtin_matrix( "mat2", ...a ),
    mat3: ( ...a ) => builtin_matrix( "mat3", ...a ),
    mat4: ( ...a ) => builtin_matrix( "mat4", ...a ),

    mat2x3: ( ...a ) => builtin_matrix( "mat2x3", ...a ),
    mat2x4: ( ...a ) => builtin_matrix( "mat2x4", ...a ),
    mat3x2: ( ...a ) => builtin_matrix( "mat3x2", ...a ),
    mat3x4: ( ...a ) => builtin_matrix( "mat3x4", ...a ),
    mat4x2: ( ...a ) => builtin_matrix( "mat4x2", ...a ),
    mat4x3: ( ...a ) => builtin_matrix( "mat4x3", ...a ),

    smooth: builtin_smooth,

    abs: builtin_abs,
    floor: builtin_floor,
    ceil: builtin_ceil,
    round: builtin_round,
    fract: builtin_fract,

    dot: builtin_dot,
    length: builtin_length,
    normalize: builtin_normalize,
    
    sqrt: builtin_sqrt,
    sin: builtin_sin,
    cos: builtin_cos,
    tan: builtin_tan,

    min: builtin_min,
    max: builtin_max,
    clamp: builtin_clamp,

    pow: builtin_pow,
}
export const BuiltinOperators = {
    '+': operator_add,
    '-': operator_sub,
    '*': operator_mul,
    '/': operator_div,

    '<': ( a, b ) => operator_compare( '<', a, b ),
    '<=': ( a, b ) => operator_compare( '<=', a, b ),
    '>': ( a, b ) => operator_compare( '>', a, b ),
    '>=': ( a, b ) => operator_compare( '>=', a, b ),
    '==': ( a, b ) => operator_compare( '==', a, b ),
    '!=': ( a, b ) => operator_compare( '!=', a, b ),
    '&&': ( a, b ) => operator_logical( '&&', a, b ),
    '||': ( a, b ) => operator_logical( '||', a, b ),
    '?:': operator_ternary,

    '-u': operator_neg,
    '+u': operator_pos,

    'swizzle': operator_swizzle,
    'index': operator_index,
}