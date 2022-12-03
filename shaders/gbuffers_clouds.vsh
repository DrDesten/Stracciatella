#if ! defined INCLUDE_GBUFFERS_CLOUDS_VSH
#define INCLUDE_GBUFFERS_CLOUDS_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef THICC_CLOUDS
#include "/lib/vertex_transform.glsl"
#else
#include "/lib/vertex_transform_simple.glsl"
#endif


out vec2 coord;
flat out vec4 glcolor;
out vec3 viewPos;

/* float getWorldPosY() {
	return gl_Vertex.y + floor((cameraPosition.y - 2.25) * 0.25) * 4 + 5.75;
} */

void main() {
	#ifdef THICC_CLOUDS

	gl_Position = gl_Vertex;
	vec3 worldPos = getWorld();
	if (worldPos.y > 156) gl_Position.y += 25;

	gl_Position = gl_ModelViewMatrix * gl_Position;
	viewPos = gl_Position.xyz;
	gl_Position = gl_ProjectionMatrix * gl_Position;

	if (gl_Position.z >= gl_Position.w) gl_Position.z = gl_Position.w;

	#else
	gl_Position = ftransform();
	viewPos     = getView();
	#endif

	coord   = getCoord();
	glcolor = gl_Color;
}

#endif