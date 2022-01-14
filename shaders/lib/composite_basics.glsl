uniform sampler2D colortex0; // Color
uniform sampler2D depthtex0; // Depth

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

vec3 getAlbedo(vec2 coord) {
    return texture2D(colortex0, coord).rgb;
}

float getDepth(vec2 coord) {
    return texture2D(depthtex0, coord).x;
}