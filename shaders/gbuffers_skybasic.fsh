#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec2 screenSizeInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;
//uniform int  isEyeInWater;

uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

vec2 screenPos = gl_FragCoord.xy * screenSizeInverse;

/* DRAWBUFFERS:0 */
void main() {
	vec3 color;

	vec3  viewDir = normalize(viewPos);
	float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

	//sunDot        = isEyeInWater == 0 ? sunDot : 1.5;
	float fogArea = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun

	vec3  newFogColor = mix(fogColor, vec3(1,0.4,0), (sunDot / (1 + sunDot)) * sunset); // Make fog Color change for sunsets
	//newFogColor       = isEyeInWater == 0 ? newFogColor : fogColor;

	color = mix(skyColor, starData.rgb, starData.a);
	color = mix(color, newFogColor, fogArea);

	FD0 = vec4(color, 1.0); //gcolor
}