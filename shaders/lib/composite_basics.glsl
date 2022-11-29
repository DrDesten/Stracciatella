
#ifndef INCLUDE_UNIFORM_sampler2D_colortex0
#define INCLUDE_UNIFORM_sampler2D_colortex0
uniform sampler2D colortex0;
#endif
// Color
#ifndef INCLUDE_UNIFORM_sampler2D_depthtex0
#define INCLUDE_UNIFORM_sampler2D_depthtex0
uniform sampler2D depthtex0;
#endif
// Depth
#ifndef INCLUDE_UNIFORM_vec2_screenSize
#define INCLUDE_UNIFORM_vec2_screenSize
uniform vec2 screenSize;
#endif

#ifndef INCLUDE_UNIFORM_vec2_screenSizeInverse
#define INCLUDE_UNIFORM_vec2_screenSizeInverse
uniform vec2 screenSizeInverse;
#endif
vec3 getAlbedo(vec2 coord) {
    return texture(colortex0, coord).rgb;
}

float getDepth(vec2 coord) {
    return texture(depthtex0, coord).x;
}