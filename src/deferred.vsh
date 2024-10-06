#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/vertex_transform_composite.glsl"

uniform int heldItemId;
uniform int heldBlockLightValue;
uniform int heldItemId2;
uniform int heldBlockLightValue2;

flat out vec4 handLight; // rgb: color, a: brightness

vec4 getHandlightColor(int itemId) {
	switch (itemId) {
		case 20: return vec4(1);                         // White
		case 21: return vec4(HANDLIGHT_COLOR_ORANGE, 1); // Orange
		case 22: return vec4(HANDLIGHT_COLOR_RED, 1);    // Red
		case 24: return vec4(HANDLIGHT_COLOR_BLUE, 1);   // Blue
		case 25: return vec4(HANDLIGHT_COLOR_PURPLE, 1); // Purple
	}
	return vec4(0);
}

void main() {
	gl_Position = getPosition();

	/* vec4  handLight1 = getHandlightColor( getID(heldItemId) );
	vec4  handLight2 = getHandlightColor( getID(heldItemId2) );
	float brightness = heldBlockLightValue / 15.;

	if (handLight1.a == 0 && handLight2.a == 0) {
		handLight = vec4(0);
	} else {
		handLight.rgb = (handLight1.rgb + handLight2.rgb) / (handLight1.a + handLight2.a);
		handLight.a   = brightness;
	} */

	vec4  handLight1           = getHandlightColor( getID(heldItemId) );
	vec4  handLight2           = getHandlightColor( getID(heldItemId2) );
	float handLight1Brightness = heldBlockLightValue / 15.; 
	float handLight2Brightness = heldBlockLightValue2 / 15.; 

	if (handLight1.a == 0 && handLight2.a == 0) {
		handLight = vec4(0);
	} else {
		handLight.rgb = (handLight1.rgb + handLight2.rgb) / (handLight1.a + handLight2.a);
		handLight.a   = handLight1Brightness + handLight2Brightness;
	}
		
}