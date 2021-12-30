#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

uniform vec3 up;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	viewPos = getView();

	glcolor = gl_Color;
	glcolor.rgb *= dot(up, getNormal()) * 0.3 + 0.7;

}