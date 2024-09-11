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

#if FOG != 0
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

	#if FOG != 0

		vec3  viewDir   = normalize(viewPos);
		vec3  playerPos = toPlayer(viewPos);
		float fog       = fogFactorTerrain(playerPos);
		
		#if FOG_ADVANCED && defined OVERWORLD 
		float fa = fogFactorAdvanced(viewDir, playerPos);
		fog      = max(fog, fa);
		#endif

		#ifdef OVERWORLD
			float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
			cave       = saturate( cave + float(cameraPosition.y > 512) );
		#else
			float cave = 1;
		#endif

		color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(viewDir), cave), fog);

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
#if defined DISTANT_HORIZONS && defined DH_TRANSPARENT_DISCARD
    if (FragOut0.a < 0.1 || !discardDH(worldPos, DH_TRANSPARENT_DISCARD_TOLERANCE)) discard;
#else
    if (FragOut0.a < 0.1) discard;
#endif
}