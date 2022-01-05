#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

uniform mat4 gbufferModelViewInverse;
varying vec3 playerPos;

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

void main() {
	gl_Position = ftransform();
	starData    = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
	viewPos     = mat3(gl_ModelViewMatrix) * gl_Vertex.xyz;
	playerPos   = mat3(gbufferModelViewInverse) * viewPos - gbufferModelViewInverse[3].xyz;
}