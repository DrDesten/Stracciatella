#version 150
#define FRAG
#define NETHER

#include "/lib/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4(fogColor, 1 );
}