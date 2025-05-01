#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/lightmap.glsl"

flat in vec2 lmcoord;
flat in vec4 glcolor;

#if OPT_SAFE
    noperspective in vec2 coord;
    #if FOG != 0
    flat in vec3 viewPos;
    #endif
#else
    in vec2 coord;
    #if FOG != 0
    in vec3 viewPos;
    #endif
#endif

#if FOG != 0
	#include "/lib/sky.glsl"
	#include "/core/transform.glsl"
	uniform float far;
#endif

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec4 FragOut1; // Even if only two channels are used, I need to set alpha in order for blending to not fuck up
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	
	color.rgb *= getCustomLightmap(vec3(lmcoord, glcolor.a), customLightmapBlend);

#if FOG != 0
	vec3  playerPos = toPlayer(viewPos);
	float fog       = fogFactorTerrain(playerPos);

	#ifdef FOG_ADVANCED
	float fa = fogFactorAdvanced(normalize(viewPos), playerPos);
	fog      = max(fog, fa);
	#endif

	color.a  *= (1-fog);
	color.a  -= Bayer4(gl_FragCoord.xy) * 0.05;
#endif

#if DITHERING >= 2
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = vec4( encodeLightmapData(vec4(0,0,1,1)), 1,1 );
}