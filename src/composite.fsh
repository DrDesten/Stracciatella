#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/core/color.glsl"
#include "/core/core/dither.glsl"

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

uniform sampler2D colortex5;

in vec2 coord;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 FragOut0;
void main() {
	ivec2 pixel = ivec2(coord * screenSize);

	vec3 colors[4] = vec3[](
		rgb2oklab(texelFetch(colortex5, pixel + ivec2(0, 0), 0).rgb),
		rgb2oklab(texelFetch(colortex5, pixel + ivec2(1, 0), 0).rgb),
		rgb2oklab(texelFetch(colortex5, pixel + ivec2(0, 1), 0).rgb),
		rgb2oklab(texelFetch(colortex5, pixel + ivec2(1, 1), 0).rgb)
	);

	float hits = 0;
	vec3 color = vec3(0);
	for (int i = 0; i < 4; i++) {
		if (colors[i] != vec3(0)) {
			hits  += 1;
			color += colors[i];
		}
	}

	if (hits > 0) {
		color = oklab2rgb(color / hits);
	}
	
	FragOut0 = vec4(color, 1);
}
