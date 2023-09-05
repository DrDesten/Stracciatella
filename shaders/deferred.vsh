#if ! defined INCLUDE_DEFERRED_VSH
#define INCLUDE_DEFERRED_VSH

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform_simple.glsl"
#if ! defined INCLUDE_UNIFORM_int_heldItemId
#define INCLUDE_UNIFORM_int_heldItemId
uniform int heldItemId; 
#endif

#if ! defined INCLUDE_UNIFORM_int_heldBlockLightValue
#define INCLUDE_UNIFORM_int_heldBlockLightValue
uniform int heldBlockLightValue; 
#endif
/*
#if ! defined INCLUDE_UNIFORM_int_heldItemId2
#define INCLUDE_UNIFORM_int_heldItemId2
uniform int heldItemId2; 
#endif

#if ! defined INCLUDE_UNIFORM_int_heldBlockLightValue2
#define INCLUDE_UNIFORM_int_heldBlockLightValue2
uniform int heldBlockLightValue2; 
#endif
*/

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

#endif