

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
	#endif

	uniform vec3  sunDir;
	uniform vec3  up;
	uniform float sunset;
	uniform vec3  skyColor;

#endif

uniform float rainStrength;

in vec2 coord;
flat in vec4 glcolor;
in vec3 viewPos;

/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 out0;
layout(location = 1) out vec4 out1;
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.a    = fstep(0.1, color.a); // Make clouds solid

	color.rgb  = mix(color.rgb, vec3(luminance(color.rgb)) * vec3(0.58,0.6,0.7), rainStrength);

	#ifdef FOG

		float fog = fogFactor(viewPos, min(far * 2, 350), gbufferModelViewInverse);

		#ifndef CUSTOM_SKY
			color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset), fog);
		#else
			color.rgb = mix(color.rgb, getSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight), fog);
		#endif

	#endif

	#if DITHERING >= 1
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	out0 = color; //gcolor
	out1 = vec4(1);
}