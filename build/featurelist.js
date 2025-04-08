import fs from "fs"
import path from "path"
import { root, src, out, shaders } from "./constants.js"
import { parseLang } from "./parseProperties.js"
import { compilePropertiesFile, parseProperties } from "./parsePropertiesID.js"

/** @param {string} shaderpath Path to shader */
export function generateFeatureList( shaderpath = src ) {
    const enUsLang = fs.readFileSync( path.join( shaderpath, "lang", "en_us.lang" ), "utf8" )
    const parsedLang = parseLang( enUsLang )

    const parsedLangScreens = Object.fromEntries(
        parsedLang.map( prop => [prop.key[1], { name: prop.key[1], comment: "", values: null }] )
    )
    const parsedLangOptions = Object.fromEntries(
        parsedLang.map( prop => [prop.key[1], { name: prop.key[1], comment: "", values: null }] )
    )
    for ( let { key: [type, id, sub], value } of parsedLang ) {
        if ( type === "screen" && sub !== "comment" ) {
            parsedLangScreens[id].name = value
            continue
        }
        if ( type === "value" && sub !== "comment" ) {
            parsedLangOptions[id].values ??= {}
            parsedLangOptions[id].values[sub] = value
            continue
        }
        if ( type === "option" ) {
            if ( sub === "comment" ) {
                parsedLangOptions[id].comment = value
            } else {
                parsedLangOptions[id].name = value
            }
            continue
        }
    }

    const shadersProperties = fs.readFileSync( path.join( shaderpath, "shaders.properties" ), "utf8" )
    const parsedProperties = parseProperties( shadersProperties ).filter( blk => blk.type === "properties" )
    const allScreens = new Map
    for ( const block of parsedProperties ) {
        for ( const p of block ) if ( p.key[0] === "screen" && p.key.at( -1 ) !== "columns" ) {
            const key = p.key[1] ?? ""
            const values = p.value
                .filter( x => x !== "<empty>" && x !== "*" )
            allScreens.set( key, values )
        }
    }

    function createScreen( keys ) {
        function isScreen( key ) {
            return /\[\w+\]/.test( key )
        }
        function getScreenKey( key ) {
            return key.match( /\[(\w+)\]/ )[1]
        }

        // Create nested options screen structure
        const screen = {}
        for ( const key of keys ) {

            if ( isScreen( key ) ) {
                const screenKey = getScreenKey( key )

                screen[screenKey] = parsedLangScreens[screenKey] ?? { name: screenKey }

                if ( allScreens.has( screenKey ) ) {
                    screen[screenKey].children = createScreen( allScreens.get( screenKey ) )
                }

            } else {

                screen[key] = parsedLangOptions[key] ?? { name: key }

            }
        }

        // Merge *[RGB] color picker options into one
        const colorPickersOpts = Object.entries( screen ).filter( ( [key] ) => /_[RGB]$/.test( key ) )
        const colorPickers = {}
        for ( let [key, value] of colorPickersOpts ) {
            value = structuredClone( value )
            value.name = value.name
                .replace( /§\w/g, "" )
                .replace( /\s*[RGB]$/, "" )
                .replace( /\s*Color$/i, "" )
            value.name += " *(RGB Color Picker)*"
            colorPickers[key.slice( 0, -2 )] ??= { data: value, keys: [] }
            colorPickers[key.slice( 0, -2 )].keys.push( key )
        }
        for ( let [_, { data, keys }] of Object.entries( colorPickers ) ) {
            if ( keys.length !== 3 ) throw new Error( [screen, data, keys] )
            screen[keys[0]] = data
            delete screen[keys[1]]
            delete screen[keys[2]]
        }

        return screen
    }
    const screen = createScreen( allScreens.get( "" ) )
    console.log( allScreens )
    console.log( screen )

    function generateFeatureList( screen, indent = -1 ) {
        let string = ""
        for ( const [key, data] of Object.entries( screen ) ) {
            let { name, comment, values, children } = data
            name = name?.replace( /§\w/g, "" )
            comment = comment?.replace( /\.(\s+|$)/g, "  \n" ).trim()
                .replace( /^(?=.)|(?<=\n)/g, "&emsp;" )
                .replace( /§c§n\/!\\§r\s*(.*)(?=  \n|$)/g, "**$1**" )
                .replace( /§c(.+?)§r/g, "**$1**" )
                .replace( /§n(.+?):?§r/g, "$1:" )

            if ( children ) {
                if ( indent === -1 ) {
                    string += `\n### ${name}\n\n`
                } else {
                    string += " ".repeat( indent * 2 ) + ` - **${name}**\n`
                }
                string += generateFeatureList( children, indent + 1 )
            } else {
                string += " ".repeat( Math.max( indent, 0 ) * 2 )
                string += ` - ${name}`
                string += values ? ` - *${Object.values( values ).map( v => v.replace( /§\w/g, "" ) ).join( ", " )}*` : ""
                string += comment ? `  \n${comment}` : ""
                string += "\n"
            }
        }
        return string
    }
    const featureList = generateFeatureList( screen )

    const dstpath = path.join( out, "feature-list.md" )
    fs.mkdirSync( out, { recursive: true } )
    fs.writeFileSync( dstpath, featureList )
    console.info( `Compiled feature list to ${dstpath}` )
}
