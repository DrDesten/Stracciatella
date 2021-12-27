#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

/*
const int colortex0Format = RGBA8; // Color Buffer
const int colortex1Format = R8;    // Empty Buffer
const int colortex2Format = R8;    // Empty Buffer
const int colortex3Format = R8;    // Effects Buffer

const vec4 colortex3ClearColor = vec4(0)

const bool colortex0Clear = false; 
const bool colortex1Clear = false; 
const bool colortex2Clear = false; 
*/


const float sunPathRotation = -15; // [-50 -49 -48 -47 -46 -45 -44 -43 -42 -41 -40 -39 -38 -37 -36 -35 -34 -33 -32 -31 -30 -29 -28 -27 -26 -25 -24 -23 -22 -21 -20 -19 -18 -17 -16 -15 -14 -13 -12 -11 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50]

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

uniform sampler2D colortex3; // Effects

#ifdef FOG
#include "/lib/transform.glsl"
#include "/lib/fog_sky.glsl"

uniform int  isEyeInWater;
uniform vec2 playerLMCSmooth;
uniform vec3 fogColor;
#endif

/* DRAWBUFFERS:0 */
void main() {
	
	#ifdef RAIN_EFFECTS
		float rain = texture2D(colortex3, coord).r;
		coord     += sin(vec2(rain * (TWO_PI * 10))) * RAIN_EFFECTS_STRENGTH;
	#endif

	vec3 color = getAlbedo(coord);

	if (isEyeInWater != 0) {
		vec3 viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac = fogExp(viewPos, FOG_UNDERWATER_DENSITY * exp(playerLMCSmooth.y * -3 + 3));

		color = mix(color, fogColor * (playerLMCSmooth.y * 0.6 + 0.4), fogFac);
	}

	

	FD0 = vec4(color, 1.0);
}