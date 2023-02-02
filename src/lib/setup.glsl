/*
// Main Color Buffer
const int colortex0Format = RGBA8;
// Lightmap Values, AO and Emissiveness information ( encoded to RG16 ) 
const int colortex1Format = RG16;
// Bound to LUT in composite ( unused otherwise )
const int colortex2Format = R8;
// Rain Stencil ( for rain refraction )
const int colortex3Format = R8;
// Colored Lights Data ( RGB: Color, A: Depth ) ( fixed resolution )
const int colortex4Format = RGBA16;
// Emissive Colors ( used for colored lights )
const int colortex5Format = RGB8;
*/


#ifdef AGRESSIVE_OPTIMISATION

    #if MC_VERSION < 11900
    const bool colortex0Clear = false;
    #endif

    const bool colortex1Clear = false;
    const bool colortex2Clear = false;

#else

    const bool colortex1Clear = true;
    const vec4 colortex1ClearColor = vec4(1,1,0,0);
    const bool colortex2Clear = false;

#endif

const bool colortex3Clear = true;
const vec4 colortex3ClearColor = vec4(0,0,0,0);

#ifdef COLORED_LIGHTS
const bool colortex4Clear = false;
const bool colortex5Clear = true;
const vec4 colortex5ClearColor = vec4(0,0,0,0);
#endif