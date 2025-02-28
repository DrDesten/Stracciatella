#include "/lib/settings.glsl"
#include "/lib/vertex_transform_composite.glsl"

#if defined COLORED_LIGHTS_TEXTURE_SIZE_COMPATIBILTY

out vec2 coord;

void main() {
	gl_Position = getPosition();
	coord       = gl_Vertex.xy;
}
#else

void main() {
	gl_Position = getPosition();
}

#endif 