#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_simple.glsl"

out vec2 coord;

void main() {
	gl_Position = getPosition();
	coord       = getCoord();
}