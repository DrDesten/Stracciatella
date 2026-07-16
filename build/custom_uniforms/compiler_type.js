const _TypeCache = new Map
export function Type( typename ) {
    function constructor(typename) {
        const type = {
            name: typename,
            underlying: "", // bool, int, uint, float, double
            unsigned: false,
            signed: false,
            integral: false,
            floating: false,
            boolean: false,

            shape: [],

            scalar: false,
            vector: false,
            matrix: false,

            vec: 1,
            rows: 1,
            cols: 1,
            square: false,

            bits: 0,
            components: 1,

            valueOf() { return this.name },
            toString() { return this.name },
        }

        const scalars = {
            bool: { bits: 1, shape: [1], boolean: true },
            int: { bits: 32, shape: [1], integral: true, signed: true },
            uint: { bits: 32, shape: [1], integral: true, unsigned: true },
            float: { bits: 32, shape: [1], floating: true },
            double: { bits: 64, shape: [1], floating: true },
        }

        if ( typename in scalars ) {
            Object.assign( type, scalars[typename] )
            type.scalar = true
            type.underlying = typename
            return type
        }

        let m

        // vectors
        if ( m = typename.match( /^(b|i|u|d)?vec([2-4])$/ ) ) {
            const prefix = m[1] ?? ""
            const dim = +m[2]

            type.vector = true
            type.shape = [dim]
            type.vec = dim
            type.components = dim
            type.rows = dim
            type.cols = 1

            const base = {
                "": { underlying: "float", floating: true, bits: 32 },
                "d": { underlying: "double", floating: true, bits: 64 },
                "i": { underlying: "int", integral: true, signed: true, bits: 32 },
                "u": { underlying: "uint", integral: true, unsigned: true, bits: 32 },
                "b": { underlying: "bool", boolean: true, bits: 1 },
            }

            Object.assign( type, base[prefix] )

            return type
        }

        // matrices
        if ( m = typename.match( /^d?mat([2-4])(?:x([2-4]))?$/ ) ) {
            const double = typename[0] === "d"
            const cols = +m[1]
            const rows = +m[2] || cols

            type.matrix = true
            type.shape = [cols, rows]
            type.rows = rows
            type.cols = cols
            type.vec = cols
            type.components = cols * rows
            type.square = cols === rows

            type.underlying = double ? "double" : "float"
            type.floating = true
            type.bits = double ? 64 : 32

            return type
        }

        throw new Error( `Unknown GLSL type '${typename}'` )
    }

    if ( _TypeCache.has( typename ) ) {
        return _TypeCache.get( typename )
    }

    const type = constructor(typename)
    _TypeCache.set( typename, type )
    return type
}
Type.bool = Type( "bool" )
Type.int = Type( "int" )
Type.uint = Type( "uint" )
Type.float = Type( "float" )
Type.double = Type( "double" )

const type_rank = {
    int: 0,
    uint: 1,
    float: 2,
    double: 3,
}

export function type_underlying( type ) {
    return Type( type.underlying )
}

function shape_eq(a, b) {
    return a.length === b.length && a.every((ad, i) => ad === b[i])
}
function shape_classify(shape) {
    return {
        scalar: shape.length === 1 && shape[0] === 1,
        vector: shape.length === 1 && shape[0] > 1,
        matrix: shape.length === 2,
    }
}

export function type_shape_eq(a, b) {
    return shape_eq(a.shape, b.shape)
}

export function type_from(shape, underlying) {
    if (shape.shape) shape = shape.shape
    if (underlying.name) underlying = underlying.name

    const { scalar, vector, matrix } = shape_classify(shape)

    if (scalar) {
        return Type(underlying)
    }

    if (vector) {
        const prefix = { bool: 'b', int: 'i', uint: 'u', float: '', double: 'd' }[underlying]
        if ( prefix === undefined )
            throw new Error( `Illegal underlying type '${underlying}' for vector` )
        return Type( `${prefix}vec${shape[0]}` )        
    }

    if (matrix) {
        const prefix = { float: '', double: 'd' }[underlying]
        if ( prefix === undefined )
            throw new Error( `Illegal underlying type '${underlying}' for matrix` )
        return Type(`${prefix}mat${shape[0]}${shape[0] === shape[1] ? "" : "x" + shape[1]}`)
    }

    throw new Error( `Illegal shape/underlying ${shape}/${underlying} combination` )
}

export function type_promote(...types) {
    // Handle Booleans
    let underlying_types = types.map(t => t.underlying)
    if (underlying_types.every(t => t === "bool")) 
        return Type.bool
    if (underlying_types.some(t => t === "bool")) 
        throw new Error( "Cannot mix boolean and numeric values" )

    // Determine underlying promotions
    let underlying = underlying_types[0]
    for (const t of underlying_types.slice(1)) {
        if (type_rank[t] > type_rank[underlying])
            underlying = t
    }

    // Determine shape promotions
    let shape = types[0]
    for (const t of types.slice(1)) {
        // scalars are always ok
        if (t.scalar) continue
        // first non-scalar, sets shape
        if (shape.scalar) {
            shape = t
            continue
        }
        // different non-scalar, illegal
        if (!shape_eq(shape.shape, t.shape)) 
            throw new Error(`Can't mix multiple different compound type shapes. Got '${shape.name}' and '${t.name}'`)
    }

    return type_from(shape.shape, underlying)
}

export function type_promote_underlying( a, b ) {
    a = type_underlying( a )
    b = type_underlying( b )

    if ( a.boolean || b.boolean ) {
        if ( a.boolean && b.boolean ) return Type.bool
        throw new Error( "Cannot mix boolean and numeric values" )
    }

    return type_rank[a.name] >= type_rank[b.name] ? a : b
}

function literal_string( type, value ) {
    if ( type.boolean )
        return value ? 'true' : 'false'

    if ( type.floating && Number.isInteger( value ) )
        return `${value}.0`

    return `${value}`
}

export const Precedence = {
    CONDITIONAL: 10,
    LOGICAL_OR: 20,
    LOGICAL_AND: 30,
    COMPARISON: 40,
    ADDITIVE: 50,
    MULTIPLICATIVE: 60,
    UNARY: 70,
    CALL: 80,
    PRIMARY: 90,
}

export const Partial = ( type, components ) => ( {
    type, components,
} )
export const Atom = ( type, value, literal = false, precedence = Precedence.PRIMARY ) => ( {
    type, value, literal, precedence,
    get components() { return [this] },
    toString() { return literal ? literal_string( type, value ) : "" + value },
    valueOf() { return this.toString() },
} )
