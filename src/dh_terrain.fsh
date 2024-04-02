#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/transform.glsl"
#include "/lib/dh.glsl"

uniform float far;

in vec2 lmcoord;
flat in vec4 glcolor;
in vec3 viewPos;
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
    vec3 playerPos = toPlayer(viewPos);
    vec3 worldPos  = toWorld(playerPos);

    if ( discardDH(worldPos) ) {
        discard;
    }
    
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
    dhNoise  = (dhNoise * 0.25 + 0.875);
    
    FragOut0      = glcolor;
    FragOut0.rgb *= dhNoise;
	FragOut1      = encodeLightmapData(vec4(lmcoord, 1,0));

#ifdef COLORED_LIGHTS

    vec3 coloredLightEmissive = vec3(0);
    if ( materialId == DH_BLOCK_LAVA || materialId == DH_BLOCK_ILLUMINATED ) {
        coloredLightEmissive = glcolor.rgb * 0.5;
    }
    
	FragOut2 = vec4(coloredLightEmissive, 1);

#endif
}