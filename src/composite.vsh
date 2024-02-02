out vec2 coord;

void main() {
	coord = gl_Vertex.xy;

	gl_Position = gl_Vertex * 2 - 1;
	gl_Position.xy /= 2;
	gl_Position.xy -= .5;
}