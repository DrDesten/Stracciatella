#ifndef INCLUDE_GBUFFERS_ENTITIES_VSH
#define INCLUDE_GBUFFERS_ENTITIES_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"
#ifndef INCLUDE_UNIFORM_vec3_up
#define INCLUDE_UNIFORM_vec3_up
uniform vec3 up; 
#endif
flat out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;
out vec3 viewPos;

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	viewPos = getView();

	glcolor = gl_Color;
	glcolor.rgb *= dot(up, getNormal()) * 0.3 + 0.7;
}

#endif