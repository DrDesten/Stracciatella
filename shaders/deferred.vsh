#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

void main() {
	gl_Position = gl_Vertex * 2 - 1;
}