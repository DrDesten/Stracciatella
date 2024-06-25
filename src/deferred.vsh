#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_composite.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;

flat out vec4 handLight; // rgb: color, a: brightness

vec3 getHandlightColor(int itemId) {
	switch (itemId) {
		case 20: return vec3(1); // White
		case 21: return HANDLIGHT_COLOR_ORANGE; // Orange
		case 22: return HANDLIGHT_COLOR_RED; // Red
		case 24: return HANDLIGHT_COLOR_BLUE; // Blue
		case 25: return HANDLIGHT_COLOR_PURPLE; // Purple
	}
	return vec3(0);
}

void main() {
	gl_Position = getPosition();

	vec4 handLight1 = vec4( getHandlightColor( getID( heldItemId ) ), heldBlockLightValue / 15. );
	vec4 handLight2 = vec4( getHandlightColor( getID( heldItemId2 ) ), heldBlockLightValue2 / 15. );

	float handLight1Mix = sqrtf01(handLight1.a); 
	float handLight2Mix = sqrtf01(handLight2.a); 

	float handLightMix = handLight1Mix != 0. && handLight2Mix != 0.
		? handLight2Mix / ( handLight1Mix + handLight2Mix )
		: 0.5;
	float handLightBrightness = sqrtf01(handLight1.a + handLight2.a);

	handLight = vec4( mix(handLight1.rgb, handLight2.rgb, handLightMix), handLightBrightness );
}