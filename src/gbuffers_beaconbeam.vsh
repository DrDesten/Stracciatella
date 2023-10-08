#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 coord;
flat out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord = getCoord();
	glcolor = gl_Color;
}
