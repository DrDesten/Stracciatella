#if ! defined INCLUDE_GBUFFERS_BASIC_VSH
#define INCLUDE_GBUFFERS_BASIC_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 lmcoord;
flat out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	if (gl_Color.a < 0.5) gl_Position.z -= 0.0005;
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}

#endif