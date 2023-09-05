#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
/* uniform int heldItemId2;
uniform int heldBlockLightValue2; */

out vec4 handLight; // rgb: color, a: brightness

void main() {
	gl_Position = ftransform();

	handLight = vec4(vec3(0),heldBlockLightValue);
	switch (getID(heldItemId)) {
		case 20:
			handLight.rgb = vec3(1); // White
			break;
		case 21:
			handLight.rgb = LIGHTMAP_COLOR_ORANGE; // Orange
			break;
		case 22:
			handLight.rgb = LIGHTMAP_COLOR_RED; // Red
			break;
		case 24:
			handLight.rgb = LIGHTMAP_COLOR_BLUE; // Blue
			break;
		case 25:
			handLight.rgb = LIGHTMAP_COLOR_PURPLE; // Purple
			break;
	}
	
}