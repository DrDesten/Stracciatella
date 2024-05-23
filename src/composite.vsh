#include "/lib/vertex_transform_composite.glsl"

out vec2 coord;

void main() {
	coord = gl_Vertex.xy;

	gl_Position = getPosition();
	gl_Position.xy /= 2;
	gl_Position.xy -= 1./2.;
}