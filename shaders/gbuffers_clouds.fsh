#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#ifdef FOG

	#include "/lib/sky.glsl"
#ifndef INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
#define INCLUDE_UNIFORM_mat4_gbufferModelViewInverse
uniform mat4 gbufferModelViewInverse; 
#endif

#ifndef INCLUDE_UNIFORM_int_isEyeInWater
#define INCLUDE_UNIFORM_int_isEyeInWater
uniform int isEyeInWater; 
#endif

#ifndef INCLUDE_UNIFORM_float_far
#define INCLUDE_UNIFORM_float_far
uniform float far; 
#endif
#ifdef CUSTOM_SKY
#ifndef INCLUDE_UNIFORM_float_daynight
#define INCLUDE_UNIFORM_float_daynight
uniform float daynight; 
#endif
#endif
#ifndef INCLUDE_UNIFORM_vec3_sunDir
#define INCLUDE_UNIFORM_vec3_sunDir
uniform vec3 sunDir; 
#endif

#ifndef INCLUDE_UNIFORM_vec3_up
#define INCLUDE_UNIFORM_vec3_up
uniform vec3 up; 
#endif

#ifndef INCLUDE_UNIFORM_float_sunset
#define INCLUDE_UNIFORM_float_sunset
uniform float sunset; 
#endif
#endif
#ifndef INCLUDE_UNIFORM_float_rainStrength
#define INCLUDE_UNIFORM_float_rainStrength
uniform float rainStrength; 
#endif
in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.a    = fstep(0.1, color.a); // Make clouds solid

	color.rgb  = mix(color.rgb, vec3(luminance(color.rgb)) * vec3(0.58,0.6,0.7), rainStrength);

	#ifdef FOG

		float fog = fogFactor(viewPos, min(far * 2, 350), gbufferModelViewInverse);

		#ifndef CUSTOM_SKY
			color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, sunset), fog);
		#else
			color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, sunset, rainStrength, daynight), fog);
		#endif

	#endif

	#if DITHERING >= 1
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	
	FragOut0 = color; //gcolor
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(1));
}