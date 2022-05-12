

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

uniform vec3 up;

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;
out vec3 viewPos;

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	viewPos = getView();

	glcolor = gl_Color;
	glcolor.rgb *= dot(up, getNormal()) * 0.3 + 0.7;

}