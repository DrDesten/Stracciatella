const _TypeCache = new Map
export function Type( typename ) {
    const name = typename.trim()
    function constructor() {
        const type = {
            name: name,
            underlying: "", // bool, int, uint, float, double
            unsigned: false,
            signed: false,
            integral: false,
            floating: false,
            boolean: false,

            scalar: false,
            vector: false,
            matrix: false,

            vec: 1,
            rows: 1,
            cols: 1,
            square: false,

            bits: 0,
            components: 1,

            valueOf() { return name },
            toString() { return name },
        }

        const scalars = {
            bool: { bits: 1, boolean: true },
            int: { bits: 32, integral: true, signed: true },
            uint: { bits: 32, integral: true, unsigned: true },
            float: { bits: 32, floating: true },
            double: { bits: 64, floating: true },
        }

        if ( name in scalars ) {
            Object.assign( type, scalars[name] )
            type.scalar = true
            type.underlying = name
            return type
        }

        let m

        // vectors
        if ( m = name.match( /^(b|i|u|d)?vec([2-4])$/ ) ) {
            const prefix = m[1] ?? ""
            const dim = +m[2]

            type.vector = true
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
        if ( m = name.match( /^d?mat([2-4])(?:x([2-4]))?$/ ) ) {
            const double = name[0] === "d"
            const rows = +m[1]
            const cols = +m[2] || rows

            type.matrix = true
            type.rows = rows
            type.cols = cols
            type.vec = cols
            type.components = rows * cols
            type.square = rows === cols

            type.underlying = double ? "double" : "float"
            type.floating = true
            type.bits = double ? 64 : 32

            return type
        }

        throw new Error( `Unknown GLSL type '${typename}'` )
    }

    if ( _TypeCache.has( name ) ) {
        return _TypeCache.get( name )
    }

    const type = constructor()
    _TypeCache.set( name, type )
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

export function type_rebase( type, underlying ) {
    underlying = typeof underlying === 'string' ? underlying : underlying.name

    if ( type.scalar )
        return Type( underlying )

    if ( type.vector ) {
        const prefix = { bool: 'b', int: 'i', uint: 'u', float: '', double: 'd' }[underlying]

        if ( prefix === undefined )
            throw new Error( `Cannot use '${underlying}' as vector component type` )

        return Type( `${prefix}vec${type.components}` )
    }

    if ( type.matrix ) {
        if ( underlying !== 'float' && underlying !== 'double' )
            throw new Error( "Matrices require floating-point components" )

        const name = type.name.replace( /^d/, '' )
        return Type( ( underlying === 'double' ? 'd' : '' ) + name )
    }

    throw new Error( `Unknown type '${type}'` )
}

export function type_promote( a, b ) {
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
