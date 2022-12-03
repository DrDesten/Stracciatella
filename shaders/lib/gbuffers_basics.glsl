#if ! defined INCLUDE_GBUFFERS_BASICS_GLSL
#define INCLUDE_GBUFFERS_BASICS_GLSL

#if MC_VERSION < 11700
    #define gtexture gcolor
#endif
#if ! defined INCLUDE_UNIFORM_sampler2D_gcolor
#define INCLUDE_UNIFORM_sampler2D_gcolor
uniform sampler2D gcolor; // Color
#endif
vec4 getAlbedo(vec2 coord) {
    return texture(gcolor, coord);
}

vec2 encodeLightmapData(vec4 data) {
    return vec4to16x2(data);
}

#endif