#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define FRAG
#define NETHER
#include "/core/math.glsl"
#include "/lib/utils.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	FragOut0 = vec4(fogColor, 1 );
}