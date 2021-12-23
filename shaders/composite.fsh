#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

/*
const int colortex0Format = RGBA8; // Color Buffer
const int colortex4Format = R8;    // Effects Buffer

const vec4 colortex4ClearColor = vec4(0)
*/


const float sunPathRotation = -15; // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex4; // Effects



/* DRAWBUFFERS:0 */
void main() {
	float rain = texture2D(colortex4, coord).r;
	//coord      = (coord - 0.499) * (rain * 0.2 + 1) + 0.5;
	coord     += sin(vec2(rain * (TWO_PI * 10))) * 0.05;

	vec3 color = getAlbedo(coord);

	//color = vec3(rain);

	

	FD0 = vec4(color, 1.0);
}