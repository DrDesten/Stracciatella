#include "/lib/settings.glsl"
#include "/lib/vertex_transform_composite.glsl"

void main() {
	#if defined FXAA || defined HQ_UPSCALING
	gl_Position = getPosition();
	#else
	gl_Position = vec4(-5); // Move it offscreen to discard (for OF versions not supporting shader config program toggling)
	#endif
}