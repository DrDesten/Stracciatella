#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/core/core/color.glsl"

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

uniform sampler2D colortex5;

in vec2 coord;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 FragOut0;
void main() {
	ivec2 pixel = ivec2(coord * screenSize);

	vec3 colors[9] = vec3[](
		texelFetch(colortex5, pixel + ivec2(-1, 1), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(0, 1), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(1, 1), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(-1, 0), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(0, 0), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(1, 0), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(-1, -1), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(0, -1), 0).rgb,
		texelFetch(colortex5, pixel + ivec2(1, -1), 0).rgb
	);

	float luma = 0;
	vec3 color = vec3(0);
	for (int i = 0; i < 9; i++) {
		float l = luminance(colors[i]);
		if (l > luma) {
			luma = l;
			color = colors[i];
		}
	}

	FragOut0 = vec4(color, 1);
}
