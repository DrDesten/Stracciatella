#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
/* uniform int heldItemId2;
uniform int heldBlockLightValue2; */

out vec4 handLight; // rgb: color, a: brightness

void main() {
	gl_Position = ftransform();

	handLight = vec4(0,0,0,heldBlockLightValue * (1./15));
	switch (heldItemId - 1000) {
		case 41:
			handLight.rgb = LIGHTMAP_COLOR_ORANGE; // Orange
			break;
		case 42:
			handLight.rgb = LIGHTMAP_COLOR_RED; // Red
			break;
		case 43:
			handLight.rgb = LIGHTMAP_COLOR_BLUE; // Blue
			break;
		case 44:
			handLight.rgb = LIGHTMAP_COLOR_PURPLE; // Purple
			break;
	}
	
}