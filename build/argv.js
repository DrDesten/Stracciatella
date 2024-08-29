/**
 * @typedef {boolean} ArgOption
 * @typedef {{[command: string]: ArgCommand} & {[option: string]: ArgOption}} ArgCommand
 */

/** @template T @param {T} schema @param {string[]} argv @param {number} [slice=2] @returns {T & {command: string}} */
export function parseArgv( schema, argv, slice = 2 ) {
    argv = argv.slice( slice )

    let options = schema
    let command = []
    while ( argv.length && typeof options[argv[0]] === "object" )
        options = options[argv[0]], command.push( argv.shift() )

    while ( argv.length ) {
        const input = argv.shift()
        if ( input.startsWith( "--" ) ) { // --option / --no-option
            const value = !input.startsWith( "--no-" )
            const arg = input.slice( value ? 2 : 5 )
            if ( arg in options ) options[arg] = value
            continue
        }
        if ( input.startsWith( "-" ) ) { // -o / -no-o
            const candidates = Object.fromEntries(
                Object.keys( options ).map( opt => [opt[0], opt] )
                    .filter( ( [opt], i, arr ) => arr.findIndex( ( [x] ) => x === opt ) === i )
            )

            const value = !input.startsWith( "-no-" )
            const args = input.slice( value ? 1 : 4 ).split( "" )

            if ( new Set( args ).size !== args.length || !args.every( o => o in candidates ) ) {
                console.error( "Unknown option:", input, candidates, args )
                continue
            }

            for ( const arg of args ) options[candidates[arg]] = value
            continue
        }
    }

    schema.command = command.join( " " )
    return schema
}