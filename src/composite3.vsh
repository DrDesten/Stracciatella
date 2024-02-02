out vec2 coord;

void main() {
	coord = gl_Vertex.xy / 27;

	gl_Position = gl_Vertex * 2 - 1;
	gl_Position.xy /= 81;
	gl_Position.xy += 2./3. + 2./9. + 2./27. + 2./81.;
}