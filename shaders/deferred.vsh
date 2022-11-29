#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#ifndef INCLUDE_UNIFORM_int_heldItemId
#define INCLUDE_UNIFORM_int_heldItemId
uniform int heldItemId; 
#endif

#ifndef INCLUDE_UNIFORM_int_heldBlockLightValue
#define INCLUDE_UNIFORM_int_heldBlockLightValue
uniform int heldBlockLightValue; 
#endif
/*
#ifndef INCLUDE_UNIFORM_int_heldItemId2
#define INCLUDE_UNIFORM_int_heldItemId2
uniform int heldItemId2; 
#endif

#ifndef INCLUDE_UNIFORM_int_heldBlockLightValue2
#define INCLUDE_UNIFORM_int_heldBlockLightValue2
uniform int heldBlockLightValue2; 
#endif
*/

out vec4 handLight; // rgb: color, a: brightness

void main() {
	gl_Position = ftransform();

	handLight = vec4(0,0,0,heldBlockLightValue);
	switch (heldItemId - 1000) {
		case 40:
			handLight.rgb = vec3(1); // White
			break;
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