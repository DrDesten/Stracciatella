const
    h = 6.62607015e-34,
    k = 1.380649e-23,
    c = 299792458,
    e = 2.718281828459045

// Inputs: Wavelength in meters
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
    }
}

function xyz2rgb( x, y, z ) {
    let r = x * 3.2406 + y * -1.5372 + z * -0.4986
    let g = x * -0.9689 + y * 1.8758 + z * 0.0415
    let b = x * 0.0557 + y * -0.2040 + z * 1.0570

    /* r = r > 0.0031308 ? ( 1.055 * Math.pow( r, 1 / 2.4 ) - 0.055 ) : r * 12.92
    g = g > 0.0031308 ? ( 1.055 * Math.pow( g, 1 / 2.4 ) - 0.055 ) : g * 12.92
    b = b > 0.0031308 ? ( 1.055 * Math.pow( b, 1 / 2.4 ) - 0.055 ) : b * 12.92 */

    return [r, g, b]
}



function integrate( func, start, end, steps ) {
    let acc = 0
    for ( let i = 0; i < steps; i++ ) {
        let x = start + ( ( i + 0.5 ) / steps ) * ( end - start )
        acc += func( x )
    }
    return acc / steps
}


function temp2xyz( temp ) {
    const coeff = [
        integrate( x => CIE1931.X( x ) * spectralDistribution( x * 1e-9, temp ), 1, 1000, 1000 ),
        integrate( x => CIE1931.Y( x ) * spectralDistribution( x * 1e-9, temp ), 1, 1000, 1000 ),
        integrate( x => CIE1931.Z( x ) * spectralDistribution( x * 1e-9, temp ), 1, 1000, 1000 ),
    ]
    return coeff
}

function temp2rgb( temp ) {
    let xyz = temp2xyz( temp )
    let rgb = xyz2rgb( ...xyz ).map( x => Math.max( 0, x ) )
    return rgb
}
function reinhard( rgb, factor = 1, exposure = 1 ) {
    return rgb.map( x => x * exposure ).map( x => x / ( x + factor ) )
}

const table = new Array( 100 ).fill( 0 )
    .map( ( _, i ) => temp2rgb( i * 100 + 100 ) )
    .map( x => x.map( n => n / Math.max( ...x ) ) )
    .map( ( x, i ) => ( x.T = i * 100 + 100, x ) )

console.log(
    table.map( c => `vec3(${c.join(", ")})` )
)