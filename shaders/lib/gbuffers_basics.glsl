#if MC_VERSION < 11700
    #define gtexture gcolor
#endif

uniform sampler2D gcolor;  // Color
uniform sampler2D lightmap; // lightmap

vec4 getAlbedo(vec2 coord) {
    return texture(gcolor, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture(lightmap, lmcoord).rgb;
}


#ifndef MC_GL_VENDOR_INTEL
uint encodeLightmapData(vec4 data) {
    return vec4toUI(data);
}
#else
vec2 encodeLightmapData(vec4 data) {
    return vec4to16x2(data);
}
#endif