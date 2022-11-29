#ifndef INCLUDE_SETUP_GLSL
#define INCLUDE_SETUP_GLSL

/*


const int colortex0Format = RGBA8;  // Color
const int colortex1Format = RG16;   // Lightmap, AO, Emissiveness (encoded)
const int colortex2Format = R8;     // Unused (LUT)
const int colortex3Format = R8;     // Effects
const int colortex4Format = RGBA16; // LightmapColor + Depth
const int colortex5Format = RGB8;   // EmissiveColor



*/

#ifdef OVERWORLD
const vec4 colortex1ClearColor = vec4(0,0,0,0);
#endif
const vec4 colortex3ClearColor = vec4(0,0,0,0);
const vec4 colortex5ClearColor = vec4(0,0,0,0);

#if MC_VERSION < 11900
const bool colortex0Clear = false;
#endif
const bool colortex1Clear = false;
const bool colortex2Clear = false;
const bool colortex3Clear = true;
const bool colortex4Clear = false;
const bool colortex5Clear = true;

#endif