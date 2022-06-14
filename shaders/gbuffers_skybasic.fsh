#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifndef CUSTOM_STARS
flat in vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
#endif

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	#ifdef CUSTOM_STARS
	FragOut0 = vec4(vec3(0), 1.0);
    if (FragOut0.a < 0.1) discard;
	#else
	FragOut0 = vec4(starData.rgb * starData.a, 1.0);
    if (FragOut0.a < 0.1) discard;
	#endif
}