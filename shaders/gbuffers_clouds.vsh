#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

/* uniform vec3 cameraPosition; */

varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

float getWorldPosY() {
	return gl_Vertex.y + floor((cameraPosition.y - 2.25) * 0.25) * 4 + 5.75;
}

void main() {
	gl_Position = ftransform();

	/* gl_Position = gl_Vertex;
	if (getWorldPosY() > 156) gl_Position.y += 10000;

	gl_Position = gl_ModelViewMatrix * gl_Position;
	viewPos = gl_Position.xyz;
	gl_Position = gl_ProjectionMatrix * gl_Position;

	if (gl_Position.z >= gl_Position.w) gl_Position.z = gl_Position.w; */

	coord   = getCoord();
	glcolor = gl_Color;
	viewPos = getView();
}