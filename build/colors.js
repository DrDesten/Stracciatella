import fs from "fs"
import path from "path"
import { out } from "./constants.js"

const
    h = 6.62607015e-34,
    k = 1.380649e-23,
    c = 299792458,
    e = 2.718281828459045

// Inputs: Wavelength in meters, Temperature in Kelvin
function spectralDistribution( wavelength, temperature ) {
    return ( ( 2 * h * c ** 2 ) / ( wavelength ** 5 ) * ( 1 / ( e ** ( ( h * c ) / ( wavelength * k * temperature ) ) - 1 ) ) )
}

const CIE1931 = {
    // Inputs: Wavelength in nanometers
    X( wavelength ) {
        const t1 = ( wavelength - 442.0 ) * ( ( wavelength < 442.0 ) ? 0.0624 : 0.0374 )
        const t2 = ( wavelength - 599.8 ) * ( ( wavelength < 599.8 ) ? 0.0264 : 0.0323 )
        const t3 = ( wavelength - 501.1 ) * ( ( wavelength < 501.1 ) ? 0.0490 : 0.0382 )
        return 0.362 * Math.exp( -0.5 * t1 * t1 ) + 1.056 * Math.exp( -0.5 * t2 * t2 )
            - 0.065 * Math.exp( -0.5 * t3 * t3 )
    },
    Y( wavelength ) {
        const t1 = ( wavelength - 568.8 ) * ( ( wavelength < 568.8 ) ? 0.0213 : 0.0247 )
        const t2 = ( wavelength - 530.9 ) * ( ( wavelength < 530.9 ) ? 0.0613 : 0.0322 )
        return 0.821 * Math.exp( -0.5 * t1 * t1 ) + 0.286 * Math.exp( -0.5 * t2 * t2 )
    },
    Z( wavelength ) {
        const t1 = ( wavelength - 437.0 ) * ( ( wavelength < 437.0 ) ? 0.0845 : 0.0278 )
        const t2 = ( wavelength - 459.0 ) * ( ( wavelength < 459.0 ) ? 0.0385 : 0.0725 )
        return 1.217 * Math.exp( -0.5 * t1 * t1 ) + 0.681 * Math.exp( -0.5 * t2 * t2 )
    },

    toRGB( [x, y, z] ) {
        let r = x * 3.2406 + y * -1.5372 + z * -0.4986
        let g = x * -0.9689 + y * 1.8758 + z * 0.0415
        let b = x * 0.0557 + y * -0.2040 + z * 1.0570
        return [r, g, b]
    }
}

const OKLAB = {
    fromLCH( [L, C, h] ) {
        return [L, C * Math.cos( h ), C * Math.sin( h ),]
    },
    toOKLAB( [r, g, b] ) {
        const l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
        const m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
        const s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

        const l_ = Math.cbrt( l )
        const m_ = Math.cbrt( m )
        const s_ = Math.cbrt( s )

        return [
            0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
            1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
            0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
        ]
    },
    toRGB( [L, a, b] ) {
        const l_ = L + 0.3963377774 * a + 0.2158037573 * b
        const m_ = L - 0.1055613458 * a - 0.0638541728 * b
        const s_ = L - 0.0894841775 * a - 1.2914855480 * b

        const l = l_ * l_ * l_
        const m = m_ * m_ * m_
        const s = s_ * s_ * s_

        return [
            + 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
            -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
            -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
        ]
    },
}

function integrate( fn, lowerBound, upperBound, steps ) {
    const delta = ( upperBound - lowerBound ) / steps
    const start = lowerBound + delta / 2
    let acc = 0
    for ( let i = 0; i < steps; i++ )
        acc += fn( start + i * delta )
    return acc / steps
}

function blackbodyXYZ( temperature ) {
    return [
        // Integrate Blackbody curve over CIE XYZ wavelength response (380nm - 750nm)
        integrate( x => CIE1931.X( x ) * spectralDistribution( x * 1e-9, temperature ), 380, 750, 1000 ),
        integrate( x => CIE1931.Y( x ) * spectralDistribution( x * 1e-9, temperature ), 380, 750, 1000 ),
        integrate( x => CIE1931.Z( x ) * spectralDistribution( x * 1e-9, temperature ), 380, 750, 1000 ),
    ]
}
function blackbodyRGB( temperature ) {
    return CIE1931.toRGB( blackbodyXYZ( temperature ) ).map( x => Math.max( 0, x ) )
}


function reinhard( rgb, factor = 1, exposure = 1 ) {
    return rgb.map( x => x * exposure ).map( x => x / ( x + factor ) )
}


export function generatePaletteColors() {
    // Custom Indexed Colors
    const customPalette = [
        [1, .3, .02],
        [.8, .05, .02],
        [0, .3, 1],
        [0.5, .8, 1],
        [.7, .3, 1],
        [0, 0, 0],
        [0, 0, 0],
    ]

    // Blackbody Colors
    const bblow = 800
    const bbhigh = 10000
    const blackbodyPalette = Array.from( { length: 8 }, ( _, i ) =>
        blackbodyRGB( ( i / 7 ) * ( bbhigh - bblow ) + bblow )
    ).map( rgb => rgb.map( x => x / Math.max( ...rgb ) ) )

    // Palette Colors
    const colorPalette = Array.from( { length: 48 }, ( _, i ) => {
        const [L, C] = [
            [1, 0.1],
            [1, 0.25],
        ][~~( i / 24 )]
        const h = i % 24 / 24 * Math.PI * 2
        const rgb = OKLAB.toRGB( OKLAB.fromLCH( [L, C, h] ) ).map( x => Math.max( 0, x ) )
        return rgb.map( x => x / Math.max( ...rgb ) )
    } )

    return [
        [0, 0, 0],
        ...customPalette,
        ...blackbodyPalette,
        ...colorPalette,
    ]
}

function generateHtmlForColors( colors ) {
    if ( !Array.isArray( colors ) || colors.some( color => color.length !== 3 || color.some( c => typeof c !== 'number' ) ) ) {
        throw new Error( "Input must be an array of [number, number, number] arrays." )
    }

    const cols = Math.floor( Math.sqrt( colors.length ) )
    const cellsize = 50 / cols

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RGB Color Grid</title>
    <style>
        *[flex] { display: flex; align-items: center; justify-content: center; }
        body { font-family: sans-serif; margin: 0; min-height: 100vh; font-size: 1em; font-weight: 900; }
        .grid { display: grid; grid-template-columns: repeat(${cols}, 1fr); gap: 1em; }
        .color { width: min(${cellsize}vh, ${cellsize}vw); height: min(${cellsize}vh, ${cellsize}vw); border-radius: 5px; }
        .index { font-weight: 900; }
        .color:hover::after {
            content: attr(data-rgb);
            position: absolute;
            bottom: 60px;
            left: 50%;
            transform: translateX(-50%);
            background: #000;
            color: #fff;
            padding: 0.3em;
            border-radius: 2px;
            white-space: nowrap;
        }
    </style>
</head>
<body flex>
    <div class="grid">
        ${colors.map( ( rgb, index ) => {
        const rgbString = `rgb(${rgb[0] * 255}, ${rgb[1] * 255}, ${rgb[2] * 255})`
        const indexColor = rgb[0] + rgb[1] + rgb[2] > 1.5 ? "#000" : "#fff"
        return `
            <div flex class="cell">
                <div flex class="color" style="background-color:${rgbString};" data-rgb="[${rgb.map( x => x.toFixed( 2 ) )}]">
                    <div class="index" style="color:${indexColor}">${index}</div>
                </div>
            </div>`
    } ).join( '' )}
    </div>
</body>
</html>`

    return html
}
export function generatePaletteHtml() {
    fs.writeFileSync( path.join( out, "colors.html" ), generateHtmlForColors( generatePaletteColors() ), { flag: "w" } )
}