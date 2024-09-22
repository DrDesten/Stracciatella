import path from "path"
import { Semver } from "./semver.js"

export class ShaderFile {
    /** @param {string} filename @param {BigInt} targetVersion @param {string[]} includes @param {string[]} defines   */
    constructor( filename, targetVersion, includes = [], defines = [] ) {
        this.filename = filename
        this.targetVersion = targetVersion
        this.includes = includes
        this.defines = defines

        this.addDefine( {
            ".gsh": "GEO",
            ".vsh": "VERT",
            ".fsh": "FRAG",
        }[path.extname( filename )] )

        this.customContent = ""
    }

    addDefine( define ) {
        if ( define ) this.defines.push( define )
        return this
    }
    addInclude( include ) {
        if ( include ) this.includes.push( include )
        return this
    }

    generate() {
        let content = ""
        content = "#version 150 compatibility\n#extension GL_ARB_explicit_attrib_location : enable"
        for ( const define of this.defines ) {
            content += `\n#define ${define}`
        }
        for ( const include of this.includes ) {
            content += `\n#include "${include}"`
        }
        content += `\n${this.customContent}`
        return content
    }
}

function simpleShaderFile( filename, version ) {
    return new ShaderFile( filename, version, [`/${filename}`] )
}

/** @param {string} filename */
function dh( filename, version ) {
    return [simpleShaderFile( filename, version )]
}

/** @param {string} filename */
function gbuffers( filename, version ) {
    if ( filename.startsWith( "gbuffers_hand" ) ) {
        return [
            simpleShaderFile( filename, version ),
            new ShaderFile( filename.replace( "gbuffers_hand", "gbuffers_hand_water" ), version, [`/${filename}`], ["HAND_WATER"] ),
        ]
    }
    if ( filename.startsWith( "gbuffers_textured" ) ) {
        return [
            simpleShaderFile( filename, version ),
            new ShaderFile( filename.replace( "gbuffers_textured", "gbuffers_textured_lit" ), version, [`/${filename}`], ["LIT"] ),
        ]
    }
    if ( filename.startsWith( "gbuffers_transparent" ) ) {
        return [
            new ShaderFile( filename.replace( "gbuffers_transparent", "gbuffers_water" ), version, [`/${filename}`] ),
        ]
    }
    if ( filename.startsWith( "gbuffers_terrain" ) ) {
        return [
            simpleShaderFile( filename, version ),
            new ShaderFile( filename.replace( "gbuffers_terrain", "gbuffers_terrain_cutout" ), version, [`/${filename}`], ["CUTOUT"] ),
        ]
    }

    return [simpleShaderFile( filename, version )]
}

/** @param {string} filename */
function deferred( filename, version ) {
    return [simpleShaderFile( filename, version )]
}

/** @param {string} filename */
function composite( filename, version ) {
    return [simpleShaderFile( filename, version )]
}

/** @param {string} filename */
function final( filename, version ) {
    return [simpleShaderFile( filename, version )]
}

/** @type {{[filename:string]:ShaderFile[]}} */
export function FileMapping( version ) {
    return new Proxy( {}, {
        get( _, name ) {
            const file = String( name )
            if ( file.startsWith( 'dh' ) ) {
                return dh( file, version )
            }
            if ( file.startsWith( 'gbuffers' ) ) {
                return gbuffers( file, version )
            }
            if ( file.startsWith( 'deferred' ) ) {
                return deferred( file, version )
            }
            if ( file.startsWith( 'composite' ) ) {
                return composite( file, version )
            }
            if ( file.startsWith( 'final' ) ) {
                return final( file, version )
            }
            return []
        },
        set() {
            return false
        }
    } )
}
