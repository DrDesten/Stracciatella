

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

varying vec2 lmcoord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	gl_Position.z -= 0.0005;
	/* if (gl_Color.a < 0.5) {
		gl_Position.z = 0;
	} */
	lmcoord = getLmCoord();
	glcolor = gl_Color;
}