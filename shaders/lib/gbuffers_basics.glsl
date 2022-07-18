#if MC_VERSION < 11700
    #define gtexture gcolor
#endif

uniform sampler2D gcolor;  // Color

vec4 getAlbedo(vec2 coord) {
    return texture(gcolor, coord);
}

vec2 encodeLightmapData(vec4 data) {
    return vec4to16x2(data);
}