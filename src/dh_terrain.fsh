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
    
    FragOut0 = glcolor;
	FragOut1 = encodeLightmapData(vec4(lmcoord, 1,0));

    vec3 coloredLightEmissive = vec3(0);
    if ( materialId == DH_BLOCK_LAVA || materialId == DH_BLOCK_ILLUMINATED ) {
        coloredLightEmissive = glcolor.rgb * 0.5;
    }
    
	#ifdef COLORED_LIGHTS
	FragOut2 = vec4(coloredLightEmissive, 1);
	#endif

    /* if ( chunkdiscardable ) {
        FragOut0 = vec4(0,1,0,1);
    }
    if ( distdiscardable ) {
        FragOut0 = vec4(0,0,1,1);
    } */
}