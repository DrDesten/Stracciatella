#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

varying vec2 coord;
varying vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord = getCoord();
	glcolor = gl_Color;
}