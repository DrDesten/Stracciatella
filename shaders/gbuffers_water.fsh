#if ! defined INCLUDE_GBUFFERS_WATER_FSH
#define INCLUDE_GBUFFERS_WATER_FSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#if ! defined INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter; 
#endif
#include "/lib/lightmap.glsl"


#ifdef FOG

	#include "/lib/sky.glsl"
#if ! defined INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
#define INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
uniform mat4 gbufferModelViewInverse; 
#endif

#if ! defined INCLUDE_UNIFORM_int_isEyeInWater
#define INCLUDE_UNIFORM_int_isEyeInWater
uniform int isEyeInWater; 
#endif

#if ! defined INCLUDE_UNIFORM_float_far
#define INCLUDE_UNIFORM_float_far
uniform float far; 
#endif
#ifdef CUSTOM_SKY
#if ! defined INCLUDE_UNIFORM_float_daynight
#define INCLUDE_UNIFORM_float_daynight
uniform float daynight; 
#endif

#if ! defined INCLUDE_UNIFORM_float_rainStrength
#define INCLUDE_UNIFORM_float_rainStrength
uniform float rainStrength; 
#endif
#endif
#if ! defined INCLUDE_UNIFORM_vec3_sunDir
#define INCLUDE_UNIFORM_vec3_sunDir
uniform vec3 sunDir; 
#endif

#if ! defined INCLUDE_UNIFORM_vec3_up
#define INCLUDE_UNIFORM_vec3_up
uniform vec3 up; 
#endif

#if ! defined INCLUDE_UNIFORM_float_sunset
#define INCLUDE_UNIFORM_float_sunset
uniform float sunset; 
#endif

#if ! defined INCLUDE_UNIFORM_ivec2_eyeBrightnessSmooth
#define INCLUDE_UNIFORM_ivec2_eyeBrightnessSmooth
uniform ivec2 eyeBrightnessSmooth; 
#endif
#endif
#if ! defined INCLUDE_UNIFORM_float_customLightmapBlend
#define INCLUDE_UNIFORM_float_customLightmapBlend
uniform float customLightmapBlend; 
#endif
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

		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);

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

#endif