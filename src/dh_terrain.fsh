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

        float texelDensity = max(
            maxc(abs(dFdx(worldPos))),
            maxc(abs(dFdy(worldPos)))
        );

        const float iter = 4;

        float dhNoise    = 0;
        float idealScale = (1./16) / texelDensity;
        float scale      = clamp(exp2(round(log2(idealScale))), 0, 4);

        vec3 globalRef = fract(worldPos / 1024) * 1024;
        for (float i = 1; i <= iter; i++) {
            vec3 seed   = floor(globalRef * scale + 1e-4) / scale;

            dhNoise   += rand(seed);
            scale     *= 2;
        }
        dhNoise /= iter;
        dhNoise  = (dhNoise * 0.25 + 0.9);

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