#ifndef INCLUDE_GBUFFERS_BEACONBEAM_VSH
#define INCLUDE_GBUFFERS_BEACONBEAM_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 coord;
flat out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord = getCoord();
	glcolor = gl_Color;
}


#endif