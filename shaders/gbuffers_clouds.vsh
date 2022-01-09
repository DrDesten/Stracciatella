#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

void main() {
	gl_Position = ftransform();
	coord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	viewPos = getView();
}