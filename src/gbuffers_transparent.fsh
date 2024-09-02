#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"

#ifdef DISTANT_HORIZONS
#include "/lib/dh.glsl"
#endif

#ifdef FOG
uniform ivec2 eyeBrightnessSmooth;
#include "/lib/sky.glsl"
#include "/core/transform.glsl"
#endif

uniform float customLightmapBlend;

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
in vec3 viewPos;

#ifdef DISTANT_HORIZONS
in vec3 worldPos;
#endif

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getCustomLightmap(vec3(lmcoord, glcolor.a), customLightmapBlend);

	#ifdef FOG

		vec3  playerPos = toPlayer(viewPos);
		float fog       = fogFactorTerrain(playerPos);
		
		#ifdef FOG_EXPERIMENTAL
			float fe = fogFactorExperimental(playerPos);
			fog = max(fog, 1 - fe);
		#endif

		#ifdef OVERWORLD
			float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
		#else
			float cave = 1;
		#endif

		color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(normalize(viewPos)), cave), fog);

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
#ifdef DISTANT_HORIZONS
    if (FragOut0.a < 0.1 || !discardDH(worldPos, 0)) discard;
#else
    if (FragOut0.a < 0.1) discard;
#endif
}