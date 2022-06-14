#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define FRAG
#define NETHER

#include "/lib/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	FragOut0 = vec4(fogColor, 1 );
}