#version 120
#define NETHER

#include "/lib/math.glsl"
uniform vec3 fogColor;

/* DRAWBUFFERS:0 */
void main() {
	gl_FragData[0] = vec4(fogColor, 1 );
}