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

export const Partial = ( type, components ) => ( {
    type, components,
} )
export const Atom = ( type, value, literal = false ) => ( {
    type, value, literal,
    get components() { return [this] },
    toString() { return "" + value },
    valueOf() { return "" + value },
} )