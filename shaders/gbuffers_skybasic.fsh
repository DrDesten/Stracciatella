#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec2 screenSizeInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3 sunDir;
uniform vec3 up;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

vec2 screenPos = gl_FragCoord.xy * screenSizeInverse;

/* DRAWBUFFERS:0 */
void main() {
	vec3 color;

	vec3  viewDir = normalize(viewPos);
	float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	float fogArea = smoothstep(sunDot * -0.5 - 0.1, 0, dot(viewDir, -up));

	color = mix(skyColor, starData.rgb, starData.a);
	color = mix(color, fogColor, fogArea);

	FD0 = vec4(color, 1.0); //gcolor
}