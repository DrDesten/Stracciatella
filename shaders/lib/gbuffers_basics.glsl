uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

uniform float nightVision;

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture2D(lightmap, lmcoord).rgb;
}

vec3 getCustomLightmap(vec2 lmcoord, float customLightmapBlend, float AO) {
    const vec3 dayColor   = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
    const vec3 nightColor = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
    
    #ifndef LIGHTMAP_COMPLEX_BLOCKLIGHT
        const vec3 blocklightColor = vec3(LIGHTMAP_BLOCK_R, LIGHTMAP_BLOCK_G, LIGHTMAP_BLOCK_B);
    #else
        #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
            float blocklightColorBlend = pow(lmcoord.x, lightmap_complex_blocklight_blend_curve);
            vec3  blocklightColor = mix(vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B), vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B), blocklightColorBlend);
        #else
            vec3  blocklightColor = mix(vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B), vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B), lmcoord.x);
        #endif
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lmcoord.y = pow(lmcoord.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lmcoord.x = pow(lmcoord.x, lightmap_blocklight_contrast);
    #endif

    vec3 skyLight   = mix(nightColor, dayColor, customLightmapBlend) * (
        lmcoord.y                                                       // Skylight
        #if LIGHTMAP_SKYLIGHT_AO != 100
        * (AO * lightmap_skylight_ao + (1. - lightmap_skylight_ao))     // Skylight AO
        #else
        * AO
        #endif
    );
    skyLight = max(skyLight, vec3((nightVision * 0.5 + LIGHTMAP_MINIMUM_LIGHT) * AO));

    vec3 blockLight = blocklightColor * (
        saturate(lmcoord.x * lmcoord.x * 1.1)                            // Blocklight
        #if LIGHTMAP_BLOCKLIGHT_AO != 100
        * (AO * lightmap_blocklight_ao + (1. - lightmap_blocklight_ao))  // Blocklight AO
        #else
        * AO
        #endif
        * saturate((mean(skyLight) * 1.15 - 0.15 ) * -LIGHTMAP_BLOCKLIGHT_REDUCTION + 1)          // Reduce Blocklight when it's bright
    );

    return blockLight + skyLight;
}
