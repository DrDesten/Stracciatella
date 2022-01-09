uniform sampler2D colortex0; // Color
uniform sampler2D depthtex0; // Depth

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

#define gl_FragData[0] gl_FragData[0]
#define gl_FragData[1] gl_FragData[1]
#define FD2 gl_FragData[2]
#define FD3 gl_FragData[3]

vec3 getAlbedo(vec2 coord) {
    return texture2D(colortex0, coord).rgb;
}

float getDepth(vec2 coord) {
    return texture2D(depthtex0, coord).x;
}