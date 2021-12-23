#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

uniform float temperature;

/* DRAWBUFFERS:04 */
void main() {
	vec4 color = getAlbedo(coord) * glcolor;
	color.rgb *= getLightmap(lmcoord);

	float rain = 0;
	if (temperature >= 0.15) { // Rain
		rain    = step(0.01, color.a);
		color.a = rain * 0.5;
	}

	FD0 = color; //gcolor
	FD1 = vec4(rain, 0, 0, 0.25);
}