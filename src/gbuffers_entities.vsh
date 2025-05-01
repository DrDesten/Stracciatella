#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/lightmap_vertex.glsl"

flat out vec2 lmcoord;
out      vec2 coord;
flat out vec4 glcolor;

void main() {
	gl_Position  = getPosition();
	coord        = getCoord();
	lmcoord      = getLmCoord();

	glcolor      = gl_Color;
	glcolor.rgb *= getEntityShading(getNormal());
}