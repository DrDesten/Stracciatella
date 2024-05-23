vec2 getCoord() {
    return gl_Vertex.xy
}

vec4 getPosition() {
    return vec4(gl_Vertex.xy * 2 - 1, 0, 1);
}