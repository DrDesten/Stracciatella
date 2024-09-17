export class Semver {    
    static parse( string ) {
        if (typeof string === "bigint") {
            return string
        }            
        if (string === "latest") {
            return Semver.parse("65535.65535.65535.65535")
        }               
        const split = string.split(".")
        const elements = split.filter(x => /\d/.test(x)).map(x => +/\d+/.exec(x)[0])
        const parsed = elements.slice(0, 4).map(x => BigInt(Math.max(Math.min(x, 2**16-1), 0)))
        const i = [ ...parsed, 0n, 0n, 0n, 0n ]
        const result = i[0] << 48n | i[1] << 32n | i[2] << 16n | i[3]
        return result
    }
}
