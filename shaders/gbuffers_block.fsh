#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

uniform vec3  fogColor;
uniform float farInverse;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb * glcolor.a;
	color.rgb *= getLightmap(lmcoord);

	color.rgb = mix(fogColor, color.rgb, exp(min(0, -sqmag(viewPos) * sq(farInverse * FOG_DISTANCE) + FOG_START)));

	FD0 = color; //gcolor
}