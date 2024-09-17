import path from "path"
import url from "url"

const __dirname = path.resolve( path.dirname( url.fileURLToPath( import.meta.url ) ) )

export const root = path.join( __dirname, "../" )
export const src = path.join( root, "src" )
export const out = path.join( root, "out" )
export const shaders = path.join( root, "shaders" )
