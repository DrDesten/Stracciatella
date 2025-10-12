#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_simple.glsl"

attribute vec4 mc_Entity;

uniform vec3 up;

out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;
flat out int  blockId;

void main() {
	gl_Position  = getPosition();
	coord        = getCoord();
	lmcoord      = getLmCoord();
	glcolor      = gl_Color;
	glcolor.rgb *= dot(up, getNormal()) * 0.4 + 0.6;
	blockId      = getID(mc_Entity);
}