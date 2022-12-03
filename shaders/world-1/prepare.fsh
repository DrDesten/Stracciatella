#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define FRAG
#define NETHER
#include "/lib/math.glsl"
#if ! defined INCLUDE_UNIFORM_vec3_fogColor
#define INCLUDE_UNIFORM_vec3_fogColor
uniform vec3 fogColor; 
#endif
/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	FragOut0 = vec4(fogColor, 1 );
}