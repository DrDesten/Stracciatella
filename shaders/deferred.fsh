#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

/* DRAWBUFFERS:0 */
void main() {
	vec3 color = getAlbedo(coord);

	FD0 = vec4(color, 1.0); //gcolor
}