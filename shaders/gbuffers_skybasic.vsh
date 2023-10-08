#if ! defined INCLUDE_GBUFFERS_SKYBASIC_VSH
#define INCLUDE_GBUFFERS_SKYBASIC_VSH

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"

#ifndef CUSTOM_STARS
flat out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
#endif

void main() {
	gl_Position = ftransform();

	#ifndef CUSTOM_STARS
	starData    = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
	#endif
}

#endif