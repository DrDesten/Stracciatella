out vec2 coord;

void main() {
	gl_Position = gl_Vertex * 2 - 1;
	coord = gl_Vertex.xy;
}