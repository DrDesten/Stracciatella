

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;

#ifdef FOG
out vec3 viewPos;
#endif

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;

	#ifdef FOG
	viewPos = getView();
	#endif
}