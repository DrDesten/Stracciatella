#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_simple.glsl"

uniform vec3 up;

out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;
out vec3 viewPos;

void main() {
	gl_Position  = getPosition();
	coord        = getCoord();
	lmcoord      = getLmCoord();
	viewPos      = getView();
	glcolor      = gl_Color;
	glcolor.rgb *= dot(up, getNormal()) * 0.4 + 0.6;
}