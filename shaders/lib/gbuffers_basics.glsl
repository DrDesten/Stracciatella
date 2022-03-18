uniform sampler2D texture;  // Color
uniform sampler2D lightmap; // lightmap

uniform float nightVision;

const vec3 lightmapDay   = vec3(LIGHTMAP_SKY_DAY_R, LIGHTMAP_SKY_DAY_G, LIGHTMAP_SKY_DAY_B);
const vec3 lightmapNight = vec3(LIGHTMAP_SKY_NIGHT_R, LIGHTMAP_SKY_NIGHT_G, LIGHTMAP_SKY_NIGHT_B);
const vec3 lightmapBlock = vec3(LIGHTMAP_BLOCK_R, LIGHTMAP_BLOCK_G, LIGHTMAP_BLOCK_B);
const vec3 lightmapComplexBlockBright = vec3(LIGHTMAP_COMPLEX_BLOCK_BRIGHT_R, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_G, LIGHTMAP_COMPLEX_BLOCK_BRIGHT_B);
const vec3 lightmapComplexBlockDark   = vec3(LIGHTMAP_COMPLEX_BLOCK_DARK_R, LIGHTMAP_COMPLEX_BLOCK_DARK_G, LIGHTMAP_COMPLEX_BLOCK_DARK_B);

const vec3 lightmapEnd    = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B) * 0.5 + vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B) * 0.5;
const vec3 lightmapNether = vec3(1,0,1);

vec4 getAlbedo(vec2 coord) {
    return texture2D(texture, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture2D(lightmap, lmcoord).rgb;
}

vec3 getCustomLightmap(vec2 lmcoord, float customLightmapBlend, float AO) {
    
    #ifndef LIGHTMAP_COMPLEX_BLOCKLIGHT
        const vec3 blocklightColor = lightmapBlock;
    #else
        #if LIGHTMAP_COMPLEX_BLOCKLIGHT_BLEND_CURVE != 50
            float blocklightColorBlend = pow(lmcoord.x, lightmap_complex_blocklight_blend_curve);
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, blocklightColorBlend);
        #else
            vec3  blocklightColor = mix(lightmapComplexBlockDark, lightmapComplexBlockBright, lmcoord.x);
        #endif
    #endif

    #if LIGHTMAP_SKYLIGHT_CONTRAST != 50
    lmcoord.y = pow(lmcoord.y, lightmap_skylight_contrast);
    #endif
    #if LIGHTMAP_BLOCKLIGHT_CONTRAST != 50
    lmcoord.x = pow(lmcoord.x, lightmap_blocklight_contrast);
    #endif

    #ifdef NETHER
    vec3 skyLight = (lightmapNether / maxc(lightmapNether));
    lmcoord.y = LIGHTMAP_NETHER_SKY_BRIGHTNESS;
    #elif defined END
    vec3 skyLight = applySaturation(lightmapEnd / maxc(lightmapEnd), LIGHTMAP_END_SKY_SATURATION);
    lmcoord.y = LIGHTMAP_END_SKY_BRIGHTNESS;
    #else
    vec3 skyLight = mix(lightmapNight, lightmapDay, customLightmapBlend);
    #endif
    skyLight *= (
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
