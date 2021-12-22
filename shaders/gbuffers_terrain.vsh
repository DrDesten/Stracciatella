#version 120

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

#ifdef WAVING

	#include "/lib/vertex_transform.glsl"
	attribute vec4 mc_Entity;
	attribute vec2 mc_midTexCoord;
	uniform float  frameTimeCounter;
	
	vec3 wavyChaotic(vec3 worldPos, float amount, float speed) {
		vec2 seed = frameTimeCounter * vec2(1.5 * WAVING_BLOCKS_SPEED, -2. * WAVING_BLOCKS_SPEED);
		seed     += (worldPos.xz * 0.5) + (worldPos.y * 0.25);
		vec2 XZ   = sin(seed) * WAVING_BLOCKS_AMOUNT;
		return vec3(XZ.x, -1e-3, XZ.y);
	}

	vec3 wavySineY(vec3 worldPos, float amount, float speed) {
		float seed = dot(worldPos, vec3(0.5, 0.1, 0.5)) + (frameTimeCounter * speed);
		return vec3(0, sin(seed) * amount, 0);
	}

#else
	#include "/lib/vertex_transform_simple.glsl"
#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;


void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
	viewPos = getView();

	#ifdef WAVING_BLOCKS

		// Waving Blocks Upper Vertices
		if ((mc_Entity.x == 1030 || mc_Entity.x == 1031) && coord.y < mc_midTexCoord.y) { 

			vec3 worldPos = getWorld();
			vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

			worldPos     += offset;

			gl_Position   = worldToClip(worldPos);

		}

		// Waving Blocks All Vertices
		if (mc_Entity.x == 1032     // Upper section of 2-Tall plants
		#ifdef WAVING_LEAVES
			|| mc_Entity.x == 1033  // Leaves
		#endif
		) {

			vec3 worldPos = getWorld();
			vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

			worldPos     += offset;

			gl_Position   = worldToClip(worldPos);

		}

	#endif
	
	#ifdef WAVING_LIQUIDS

		// Waving Liquids
		if (mc_Entity.x == 1020) {

			vec3  worldPos = getWorld();
			float flowHeight = fract(worldPos.y + 0.01);
			
			vec3 offset   = wavySineY(worldPos, WAVING_LIQUIDS_AMOUNT * flowHeight, WAVING_LIQUIDS_SPEED);
			worldPos     += offset;

			gl_Position   = worldToClip(worldPos);

		}
	
	#endif

}