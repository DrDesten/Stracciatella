#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/composite_basics.glsl"

/*
const int colortex0Format = RGB8;  // Color
const int colortex1Format = R8;    // FXAA Luma
const int colortex2Format = R8;    // Empty
const int colortex3Format = R8;    // Effects

const vec4 colortex3ClearColor = vec4(0)

const bool colortex0Clear = false; 
const bool colortex1Clear = false; 
const bool colortex2Clear = false; 
*/

const float wetnessHalflife = 200;
const float drynessHalflife = 400;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;



#ifdef RAIN_EFFECTS
uniform sampler2D colortex3; // Rain Effects
#endif

#include "/lib/transform.glsl"
#include "/lib/fog_sky.glsl"

uniform int  isEyeInWater;
uniform vec2 playerLMCSmooth;
uniform vec3 fogColor;

uniform float blindness;
uniform float nightVision;

/* DRAWBUFFERS:0 */
void main() {
	
	#ifdef RAIN_EFFECTS
		float rain = texture2D(colortex3, coord).r;
		coord     += sin(vec2(rain * (TWO_PI * 10))) * RAIN_EFFECTS_STRENGTH;
	#endif

	vec3 color = getAlbedo(coord);

	if (isEyeInWater == 2) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogExp(viewPos, 2);

		color = mix(color, fogColor * 0.75, fogFac);
	} else if (isEyeInWater != 0) {
		vec3  viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		float fogFac  = fogExp(viewPos, FOG_UNDERWATER_DENSITY * exp(playerLMCSmooth.y * -FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE + FOG_UNDERWATER_DENSITY_DEPTH_INFLUENCE));

		color = mix(color, fogColor * (playerLMCSmooth.y * 0.6 + 0.4), saturate(nightVision * -0.1 + fogFac));
	}

	if (blindness > 1e-10) {
		vec3 viewPos = toView(vec3(coord, getDepth(coord)) * 2 - 1);
		color *= saturate(1. / (sqmag(viewPos) * blindness));
	}

	#if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	
	gl_FragData[0] = vec4(color, 1.0);
}