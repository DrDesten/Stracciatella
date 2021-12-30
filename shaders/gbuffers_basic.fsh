#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 lmcoord;
varying vec4 glcolor;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = vec4(glcolor.rgb, fstep(0.1, glcolor.a));
	color.rgb *= getLightmap(lmcoord);

	FD0 = color; //gcolor
}