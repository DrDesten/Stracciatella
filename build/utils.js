/** @param {any} obj @param {(value: undefined|null|boolean|number|bigint|symbol|string|Function, key: string) => boolean} fn  */
export function filterDeep( obj, fn ) {
    if ( typeof obj !== 'object' || obj === null ) return obj
    const filtered = structuredClone( obj )
    for ( const key of Object.getOwnPropertyNames( filtered ) ) {
        let value = filtered[key]
        if ( typeof value === 'object' && value !== null ) value = filterDeep( value, fn )
        if ( fn( value, key ) ) continue
        else delete filtered[key]
    }
    return filtered
}