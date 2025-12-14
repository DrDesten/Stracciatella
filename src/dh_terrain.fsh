#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/dh.glsl"

uniform vec3 cameraPosition;
uniform float far;

in vec2 lmcoord;
in vec4 glcolor;
in vec3 worldPos;
flat in int materialId;

#ifdef COLORED_LIGHTS
/* DRAWBUFFERS:015 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
layout(location = 2) out vec4 FragOut2;
#else
/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
#endif
void main() {
    bool isCloud =  worldPos.y > 400; 
#ifdef DH_TERRAIN_DISCARD
#ifdef DH_DISCARD_SMOOTH
	float playerDistSq = sqmag(worldPos - cameraPosition);
    if ( !isCloud && playerDistSq < sq(far * .85 - DH_TERRAIN_DISCARD_TOLERANCE) ) {
        discard;
    }
#else
    if ( !isCloud && discardDH(worldPos, DH_TERRAIN_DISCARD_TOLERANCE) ) {
        discard;
    }
#endif
#endif
    
    vec4  color        = vec4(glcolor.rgb, 1);
    float ao           = glcolor.a;
    float emissiveness = 0;

    if ( !isCloud ) {

        // Noise Shaping
        float baseScale   = 1; 
        float octaveScale = 2;
        float octaveDecay = 1.5;

        float valueShift = 0.9;
        float valueScale = 0.25;

        switch (materialId) {
            case DH_BLOCK_LEAVES: { // All types of leaves, bamboo, or cactus
                baseScale   = 2;
                octaveDecay = 1.5;
                valueShift  = 0.6;
                valueScale  = 1.3;
            } break;
            case DH_BLOCK_STONE: { // Stone or ore
            
            } break;
            case DH_BLOCK_WOOD: { // Any wooden item
            
            } break;
            case DH_BLOCK_METAL: { // Any block that emits a metal or copper sound
            
            } break;
            case DH_BLOCK_DIRT: { // Dirt, grass, podzol, and coarse dirt
                valueShift = 0.8;
                valueScale = 0.5;
            } break;
            case DH_BLOCK_LAVA: { // Lava
                octaveDecay = 1.5;
                valueShift  = 0.6;
                valueScale  = 0.8;
            } break;
            case DH_BLOCK_DEEPSLATE: { // Deepslate
            
            } break;
            case DH_BLOCK_SNOW: { // Snow
                baseScale   = 0.25;
                valueShift  = 0.95;
                valueScale  = 0.1;
            } break;
            case DH_BLOCK_SAND: { // Sand and red sand
                baseScale   = 1;
                octaveDecay = 2;
                valueShift  = 1;
                valueScale  = 0.3;
            } break;
            case DH_BLOCK_TERRACOTTA: { // Terracotta
                valueScale  = 0.1;
            } break;
            case DH_BLOCK_NETHER_STONE: { // Blocks that have the "base_stone_nether" tag
            
            } break;
        }

        float texelDensity = max(
            maxc(abs(dFdx(worldPos))),
            maxc(abs(dFdy(worldPos)))
        );

        float idealScale = (1./16) * baseScale / texelDensity;
        float scale      = clamp(exp2(round(log2(idealScale))), 0, 4);
        vec3  globalRef  = fract(worldPos / 1024) * 1024;

        float dhNoise = 0;
        float tw      = 0;
        float w       = 1;
        for (float i = 1; i <= 4; i++) {
            vec3 seed = floor(globalRef * scale + 1e-2) / scale;
        
            dhNoise  += rand(seed) * w;

            scale    *= octaveScale;
            w        *= octaveDecay;
            tw       += w; 
        }
        dhNoise /= tw;
        dhNoise  = (dhNoise * valueScale + valueShift);

        color.rgb *= dhNoise;
        
#ifdef HDR_EMISSIVES
            
        bool isEmissive = materialId == DH_BLOCK_LAVA || materialId == DH_BLOCK_ILLUMINATED;
        bool isLava     = materialId == DH_BLOCK_LAVA;
        if ( isEmissive ) {
            color.rgb    = tm_reinhard_sqrt_inverse(color.rgb * 0.996, 0.5);

            if (isLava) emissiveness = saturate(maxc(color.rgb) * 6 - 3) * 0.65;
            else emissiveness = saturate(maxc(color.rgb) * 7 - 2);

            color.rgb += (emissiveness * HDR_EMISSIVES_BRIGHTNESS * 1.5) * color.rgb;
            color.rgb  = tm_reinhard_sqrt(color.rgb, 0.5);
        }

#endif

    }

    FragOut0 = color;
	FragOut1 = encodeLightmapData(vec4(lmcoord, ao, emissiveness));

#ifdef COLORED_LIGHTS

    vec3 coloredLightEmissive = vec3(0);
    if ( materialId == DH_BLOCK_LAVA || materialId == DH_BLOCK_ILLUMINATED ) {
        coloredLightEmissive = glcolor.rgb;
    }
    
	FragOut2 = vec4(coloredLightEmissive, 1);

#endif
}