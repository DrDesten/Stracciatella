#version 150 compatibility
#extension GL_ARB_explicit_attrib_location : enable
#define VERT
#define NETHER
void main() {
    gl_Position = ftransform();
}