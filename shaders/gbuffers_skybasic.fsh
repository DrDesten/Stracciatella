#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/fog_sky.glsl"

uniform vec2 screenSizeInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;
#ifdef CUSTOM_SKY
uniform float daynight;
uniform float rainStrength;
#endif

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	#ifndef CUSTOM_SKY
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset);
	#else
	vec4 sky = getSkyColor_fogArea(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight);
	#endif

	float starMask = 1 - sky.a;
	
	vec3 color = mix(sky.rgb, saturate(starData.rgb * STAR_BRIGHTNESS), starData.a * starMask);

	//color = fogColor;
	//color = skyColor;
	//color = starData.aaa;

	FD0 = vec4(color, 1.0); //gcolor
}