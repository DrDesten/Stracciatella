/**
 * @typedef {boolean} ArgOption
 * @typedef {{[command: string]: ArgCommand} & {[option: string]: ArgOption}} ArgCommand
 */

/** @template T @param {T} schema @param {string[]} argv @param {number} [slice=2] @returns {T & {command: string}} */
export function parseArgv( schema, argv, slice = 2 ) {
    argv = argv.slice( slice )

    // Resolve subcommand
    let options = schema
    let command = []
    while ( argv.length && typeof options[argv[0]] === "object" )
        options = options[argv[0]], command.push( argv.shift() )
    schema.command = command.join( " " )

    if (argv.length && !argv[0].startsWith("-")) {
        console.warn(`Unknown command "${[...command, argv[0]].join(" ")}"`)
        return schema
    }

    // Filter out subcommands from options
    let keys = Object.keys(options).filter(key => typeof options[key] !== "object")
    let fullkeys = Object.fromEntries(keys.map(key => [key, key]))
    let shortkeys = Object.fromEntries(keys.map(key => [key[0], key]).reverse())
    while ( argv.length ) {
        const input = argv.shift()
        if ( input.startsWith( "--" ) ) { // --option / --no-option
            const value = !input.startsWith( "--no-" )
            const arg = input.slice( value ? 2 : 5 )

            if ( !(arg in fullkeys) ) {
                console.warn(`Unknown option "${arg}"`)
                continue
            }
            
            options[arg] = value
            continue
        }
        if ( input.startsWith( "-" ) ) { // -o / -no-o
            const value = !input.startsWith( "-no-" )
            const args = input.slice( value ? 1 : 4 ).split( "" )

            if ( !args.every( o => o in shortkeys ) ) {
                const unknowns = [...new Set(args)].filter(o => !(o in shortkeys))
                console.warn( `Unknown options: ${unknowns.map(o => `"${o}"`)}` )
                continue
            }
            if ( new Set(args).size !== args.length ) {
                const duplicates = args.filter((o,i,a) => a.indexOf(o) !== i)
                console.warn(`Duplicate options: ${duplicates.map(o => `"${o}"`)}`)
                continue
            }

            for ( const arg of args ) options[shortkeys[arg]] = value
            continue
        }
    }

    return schema
}