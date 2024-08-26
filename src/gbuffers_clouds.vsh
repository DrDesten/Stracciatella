#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/vertex_transform.glsl"

out vec2 coord;
flat out vec4 glcolor;
out vec3 viewPos;
out vec3 playerPos;

/* float getWorldPosY() {
	return gl_Vertex.y + floor((cameraPosition.y - 2.25) * 0.25) * 4 + 5.75;
} */

void main() {
#ifdef DISTANT_HORIZONS
	gl_Position = vec4(-1);
#else
	coord       = getCoord();
	glcolor     = gl_Color;
	gl_Position = ftransform();
	viewPos     = getView();
	playerPos   = toPlayer(viewPos);
#endif
}