#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"


#ifdef FOG

	#include "/lib/sky.glsl"
	#include "/lib/transform.glsl"

	uniform int   isEyeInWater;
	uniform float far;

	#if defined CUSTOM_SKY
		uniform float daynight;
		uniform float rainStrength;
	#endif

	uniform vec3  sunDir;
	uniform vec3  up;
	uniform float sunset;
	uniform ivec2 eyeBrightnessSmooth;

#endif

uniform float customLightmapBlend;

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	
	color.rgb *= getCustomLightmap(vec3(lmcoord, glcolor.a), customLightmapBlend);

	#ifdef FOG

		vec3 playerPos = toPlayer(viewPos);
		#ifndef DISTANT_HORIZONS
		float fog = fogFactorTerrain(playerPos);
		#else 
		float fog = fogFactorTerrainDH(playerPos);
		#endif

		#ifdef OVERWORLD
			float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
		#else
			float cave = 1;
		#endif

		#ifndef CUSTOM_SKY
			color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(normalize(viewPos), sunDir, up, sunset, isEyeInWater), cave), fog);
		#else
			color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(normalize(viewPos), sunDir, up, sunset, rainStrength, daynight, isEyeInWater), cave), fog);
		#endif

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
}