

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"


#include "/lib/fog_sky.glsl"

#ifdef FOG

	uniform mat4  gbufferModelViewInverse;
	uniform vec3  fogColor;
	uniform int   isEyeInWater;
	uniform float far;

	#ifdef CUSTOM_SKY
		uniform float daynight;
		uniform float rainStrength;
	#endif

	#if FOG_QUALITY == 1

		uniform vec3  sunDir;
		uniform vec3  up;
		uniform float sunset;
		uniform vec3  skyColor;
		uniform ivec2 eyeBrightnessSmooth;

	#endif

#endif

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	
	#ifndef CUSTOM_LIGHTMAP
	color.rgb *= getLightmap(lmcoord) * glcolor.a;
	#else
	color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);
	#endif


	#ifdef FOG

		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);

		#if FOG_QUALITY == 1

			#ifdef OVERWORLD
				float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
			#else
				float cave = 1;
			#endif

			#ifndef CUSTOM_SKY
				color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, isEyeInWater), cave), fog);
			#else
				color.rgb  = mix(color.rgb, mix(fogCaveColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight, isEyeInWater), cave), fog);
			#endif

		#else

			#if defined FOG_CUSTOM_COLOR && !defined NETHER
				color.rgb = mix(color.rgb, getCustomFogColor(rainStrength, daynight), fog);
			#else
				color.rgb = mix(color.rgb, fogColor, fog);
			#endif

		#endif

	#endif

    #if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
}