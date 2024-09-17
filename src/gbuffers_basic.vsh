#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 lmcoord;
flat out vec4 glcolor;

void main() {
	gl_Position = getPosition();
	lmcoord     = getLmCoord();
	glcolor     = gl_Color;
}