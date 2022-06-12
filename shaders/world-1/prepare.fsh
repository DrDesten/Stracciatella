#version 150
#extension GL_ARB_explicit_attrib_location : enable
#define FRAG
#define NETHER

#include "/lib/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 out0;
void main() {
	out0 = vec4(fogColor, 1 );
}