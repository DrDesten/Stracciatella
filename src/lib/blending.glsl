#include "/core/core/color.glsl"

// OKLAB
#if BLENDING == 1

vec3 blendColor(vec3 color) {
    color    = rgb2oklab(saturate(color));
    color.yz = color.yz * .5 + .5;
    return color;
}
vec3 unBlendColor(vec3 color) {
    color.yz = color.yz * 2 - 1;
    color    = oklab2rgb(color);
    return color;
}

// RGB
#else 

vec3 blendColor(vec3 color) { return color; }
vec3 unBlendColor(vec3 color) { return color; }

#endif
