#if ! defined INCLUDE_GBUFFERS_HAND_VSH
#define INCLUDE_GBUFFERS_HAND_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

flat out vec2 lmcoord;
out vec2 coord;
flat out vec4 glcolor;

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;

	//float normalCheck = min(min(min(min(abs(gl_Normal.x - 1.0), abs(gl_Normal.x + 1.0)), abs(gl_Normal.z - .9)), abs(gl_Normal.y + .9)), abs(gl_Normal.y - .9)) * 10;

	/* gl_ModelViewMatrix
	1,0,0,0
	0,1,0,0
	0,0,1,0
	0,0,0,1
	*/

	/* gl_ProjectionMatrix
	1,0,0
	0,1.4,0
	0,0,-1.3
	*/
	/* float s = sin(frameTimeCounter * 2.5);
	float c = cos(frameTimeCounter * 2.5);
	mat4 rotation = mat4(
		vec4(c,s,0,0),
		vec4(-s,c,0,0),
		vec4(0,0,1,0),
		vec4(0,0,0,1)
	);
	vec4 offset = gl_Vertex.x > 0 ? vec4(.6,-.5,0,0) : vec4(-.6,-.5,0,0);
	vec4 finaloffset = vec4(0,.1,0,0);
	gl_Position = gl_ModelViewProjectionMatrix * ((rotation * (gl_Vertex - offset)) + offset + finaloffset); */
}

#endif