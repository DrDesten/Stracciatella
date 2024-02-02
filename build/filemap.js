import path from "path"

export class ShaderFile {
    /** @param {string} filename @param {string[]} includes @param {string[]} defines   */
    constructor( filename, includes = [], defines = [] ) {
        this.filename = filename
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
        let content = "#version 150 compatibility\n#extension GL_ARB_explicit_attrib_location : enable"
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

function simpleShaderFile( filename ) {
    return new ShaderFile( filename, [`/${filename}`] )
}

/** @param {string} filename */
function gbuffers( filename ) {
    if ( filename.startsWith( "gbuffers_hand" ) ) {
        return [
            simpleShaderFile( filename ),
            new ShaderFile( filename.replace( "gbuffers_hand", "gbuffers_hand_water" ), [`/${filename}`], ["HAND_WATER"] ),
        ]
    }
    if ( filename.startsWith( "gbuffers_textured" ) ) {
        return [
            simpleShaderFile( filename ),
            new ShaderFile( filename.replace( "gbuffers_textured", "gbuffers_textured_lit" ), [`/${filename}`], ["LIT"] ),
        ]
    }
    if ( filename.startsWith( "gbuffers_transparent" ) ) {
        return [
            new ShaderFile( filename.replace( "gbuffers_transparent", "gbuffers_water" ), [`/${filename}`] ),
        ]
    }

    return [simpleShaderFile( filename )]
}

/** @param {string} filename */
function deferred( filename ) {
    return [simpleShaderFile( filename )]
}

/** @param {string} filename */
function composite( filename ) {
    return [simpleShaderFile( filename )]
}

/** @param {string} filename */
function final( filename ) {
    return [simpleShaderFile( filename )]
}

/** @type {{[filename:string]:ShaderFile[]}} */
export const FileMapping = new Proxy( {}, {
    get( _, name ) {
        const file = String( name )
        if ( file.startsWith( 'gbuffers' ) ) {
            return gbuffers( file )
        }
        if ( file.startsWith( 'deferred' ) ) {
            return deferred( file )
        }
        if ( file.startsWith( 'composite' ) ) {
            return composite( file )
        }
        if ( file.startsWith( 'final' ) ) {
            return final( file )
        }
        return []
    },
    set() {
        return false
    }
} )