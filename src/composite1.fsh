#include "/lib/settings.glsl"
#include "/core/math.glsl"

uniform vec2 screenSize;
uniform vec2 screenSizeInverse;

uniform sampler2D colortex6;

in vec2 coord;

/* DRAWBUFFERS:6 */
layout(location = 0) out vec4 FragOut0;
void main() {
	ivec2 pixel = ivec2(coord * screenSize);

	vec3 colors[9] = vec3[]( vec3(0),vec3(0),vec3(0),vec3(0),vec3(0),vec3(0),vec3(0),vec3(0),vec3(0) );

	if (pixel.x < int(screenSize.x) / 3 && pixel.y < int(screenSize.y) / 3) {
		colors = vec3[](
			texelFetch(colortex6, pixel + ivec2(-1, 1), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(0, 1), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(1, 1), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(-1, 0), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(0, 0), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(1, 0), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(-1, -1), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(0, -1), 0).rgb,
			texelFetch(colortex6, pixel + ivec2(1, -1), 0).rgb
		);
	}

	float hits = 0;
	vec3 color = vec3(0);
	for (int i = 0; i < 9; i++) {
		if (colors[i] != vec3(0)) {
			hits  += 1;
			color += colors[i];
		}
	}

	if (hits > 0) {
		color = color / hits;
	}
	
	FragOut0 = vec4(color, 1);
}
