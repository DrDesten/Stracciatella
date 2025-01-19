#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"

#if (defined DISTANT_HORIZONS) || defined WAVING_BLOCKS || defined WAVING_LIQUIDS
#include "/lib/vertex_transform.glsl"
#else
#include "/lib/vertex_transform_simple.glsl"
#endif

#if defined WAVING_BLOCKS || defined WAVING_LIQUIDS

	#include "/lib/time.glsl"

	attribute vec4 mc_Entity;
		
	vec3 wavySineY(vec3 worldPos, float amount, float speed) {
		float seed = dot(worldPos, vec3(0.5, 0.1, 0.5)) + (time * speed);
		return vec3(0, sin(seed) * amount, 0);
	}

#endif

#if defined DISTANT_HORIZONS
uniform float far;
out vec3 worldPos;
#endif

out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;
out vec3 viewPos;

void main() {
	gl_Position = getPosition();
	coord       = getCoord();
	lmcoord     = getLmCoord();
	glcolor     = gl_Color;
	viewPos     = getView();
	
	#if defined DISTANT_HORIZONS
	worldPos = getWorld();
	#endif

	#ifdef WAVING_LIQUIDS

	// Waving Liquids
	if (getID(mc_Entity) == 1) {

		#ifndef DISTANT_HORIZONS
		vec3 worldPos = getWorld();
		#endif

		float flowHeight = fract(worldPos.y + 0.01);
		
		float offset  = wavySineY(worldPos, WAVING_LIQUIDS_AMOUNT * flowHeight, WAVING_LIQUIDS_SPEED * 2.).y;
		offset       -= WAVING_LIQUIDS_AMOUNT * flowHeight * 0.5;

		#if defined DISTANT_HORIZONS
		float edgeFade = 1 - smoothstep(0.75, 0.95, sqmag(worldPos.xz - cameraPosition.xz) / (far * far));
		offset        *= edgeFade;
		#endif

		worldPos.y   += offset;
		gl_Position   = worldToClip(worldPos);

	}
	
	#endif
}