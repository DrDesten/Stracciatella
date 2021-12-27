uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

#define FD0 gl_FragData[0]
#define FD1 gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture2D(lightmap, lmcoord).rgb;
}

vec3 getCustomLightmap(vec2 lmcoord, float customLightmapBlend, float AO) {
    const vec3 dayColor   = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
    const vec3 nightColor = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
    
    const vec3 blocklightColor = vec3(LIGHTMAP_BLOCK_R, LIGHTMAP_BLOCK_G, LIGHTMAP_BLOCK_B);

    vec3 skyLight   = mix(nightColor, dayColor, customLightmapBlend) * (
        lmcoord.y *                                                      // Skylight
        (AO * LIGHTMAP_SKYLIGHT_AO + (1. - LIGHTMAP_SKYLIGHT_AO))        // Skylight AO
    );

    vec3 blockLight = blocklightColor * (
        saturate(lmcoord.x * lmcoord.x * 1.1) *                          // Blocklight
        (AO * LIGHTMAP_BLOCKLIGHT_AO + (1. - LIGHTMAP_BLOCKLIGHT_AO)) *  // Blocklight AO
        (mean(skyLight) * -0.5 + 1)                                      // Reduce Blocklight when it's bright
    );

    return blockLight + skyLight;
}
