#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_simple.glsl"
#include "/lib/lightmap_vertex.glsl"

uniform int  heldItemId;

flat out vec2  lmcoord;
out      vec2  coord;
flat out vec4  glcolor;
flat out float emissiveness;

void main() {
	gl_Position  = getPosition();
	coord        = getCoord();
	lmcoord      = getLmCoord();

	glcolor      = gl_Color;
	glcolor.rgb *= getEntityShading(getNormal());

	switch (getID(heldItemId)) {
		case 20:
		case 21:
		case 22:
		case 24:
		case 25:
			emissiveness = 1.0;
			break;
		default:
			emissiveness = 0.0;
	}
}