#version 130

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"

uniform float  frameTimeCounter;

#ifdef WAVING

	#include "/lib/vertex_transform.glsl"
	attribute vec2 mc_midTexCoord;

	#ifdef WORLD_TIME_ANIMATION

		uniform int worldTime;
	
		vec3 wavyChaotic(vec3 worldPos, float amount, float speed) {
			vec2 seed = (worldTime * (1./24.)) * vec2(1.5 * speed, -2. * speed);
			seed     += worldPos.xz + (worldPos.y * 0.25);
			vec2 XZ   = sin(seed) * amount;
			return vec3(XZ.x, -1e-3, XZ.y);
		}

		vec3 wavySineY(vec3 worldPos, float amount, float speed) {
			float seed = dot(worldPos, vec3(0.5, 0.1, 0.5)) + ((worldTime * (1./24.)) * speed);
			return vec3(0, sin(seed) * amount, 0);
		}

	#else

		vec3 wavyChaotic(vec3 worldPos, float amount, float speed) {
			vec2 seed = frameTimeCounter * vec2(1.5 * speed, -2. * speed);
			seed     += worldPos.xz + (worldPos.y * 0.25);
			vec2 XZ   = sin(seed) * amount;
			return vec3(XZ.x, -1e-3, XZ.y);
		}

		vec3 wavySineY(vec3 worldPos, float amount, float speed) {
			float seed = dot(worldPos, vec3(0.5, 0.1, 0.5)) + (frameTimeCounter * speed);
			return vec3(0, sin(seed) * amount, 0);
		}

	#endif

#elif defined RAIN_PUDDLES
	#include "/lib/vertex_transform.glsl"
#else
	#include "/lib/vertex_transform_simple.glsl"
#endif

attribute vec4 mc_Entity;

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

#ifdef RAIN_PUDDLES
uniform float rainPuddle;
varying float puddle;
varying vec2  blockCoords;
#endif

#ifdef BLINKING_ORES
varying float oreBlink;
#endif

void main() {
	gl_Position = ftransform();
	coord   = getCoord();
	lmcoord = getLmCoord();
	glcolor = gl_Color;
	viewPos = getView();

	#ifdef BLINKING_ORES

		oreBlink = sin(frameTimeCounter * 3) * 0.5 + 0.5;

		switch (int(mc_Entity.x + 0.5)) {

			#ifdef BLINKING_ORES_DIAMOND
				case 2000: break;
			#endif
			#ifdef BLINKING_ORES_ANCIENT_DEBRIS
				case 2001: break;
			#endif
			#ifdef BLINKING_ORES_IRON
				case 2002: break;
			#endif
			#ifdef BLINKING_ORES_GOLD
				case 2003: break;
			#endif
			#ifdef BLINKING_ORES_COPPER
				case 2004: break;
			#endif
			#ifdef BLINKING_ORES_REDSTONE
				case 2005: break;
			#endif
			#ifdef BLINKING_ORES_LAPIS
				case 2006: break;
			#endif
			#ifdef BLINKING_ORES_EMERALD
				case 2007: break;
			#endif
			#ifdef BLINKING_ORES_COAL
				case 2008: break;
			#endif
			#ifdef BLINKING_ORES_NETHER_QUARZ
				case 2009: break;
			#endif
			#ifdef BLINKING_ORES_NETHER_GOLD
				case 2010: break;
			#endif

			default:
				oreBlink = 0;
		}

	#endif
	

	#ifdef WAVING_BLOCKS

		// Waving Blocks Upper Vertices
		if ((mc_Entity.x == 1030 || mc_Entity.x == 1031) && coord.y < mc_midTexCoord.y) { 

			vec3 worldPos = getWorld();
			vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

			worldPos     += offset;

			gl_Position   = worldToClip(worldPos);

		}

		#ifdef WAVING_LANTERNS

		// Waving Lanterns
		else if (mc_Entity.x == 1034) {

			vec3 worldPos = getWorld();
			vec3 offset   = wavyChaotic(worldPos, (WAVING_BLOCKS_AMOUNT * 0.3), WAVING_BLOCKS_SPEED);

			worldPos     += offset * (1 - fract(worldPos.y - 0.01));

			gl_Position   = worldToClip(worldPos);

		}

		#endif

		// Waving Blocks All Vertices
		else if (mc_Entity.x == 1032     // Upper section of 2-Tall plants
		#ifdef WAVING_LEAVES
			|| mc_Entity.x == 1033  // Leaves
		#endif
		) {

			vec3 worldPos = getWorld();
			vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

			worldPos     += offset;

			gl_Position   = worldToClip(worldPos);

		}

		#ifdef WAVING_LILYPADS

		else if (mc_Entity.x == 1035) {

			vec3  worldPos  = getWorld();

			float offset  = wavySineY(worldPos, WAVING_LIQUIDS_AMOUNT, WAVING_LIQUIDS_SPEED * 2).y;
			worldPos.y   += offset;

			gl_Position   = worldToClip(worldPos);

		}
		
		#endif

	#endif
	
	#ifdef WAVING_LIQUIDS

		// Waving Liquids
		if (mc_Entity.x == 1020) {

			vec3  worldPos  = getWorld();
			float flowHeight = fract(worldPos.y + 0.01);

			float offset  = wavySineY(worldPos, WAVING_LIQUIDS_AMOUNT * flowHeight, WAVING_LIQUIDS_SPEED).y;
			offset       -= WAVING_LIQUIDS_AMOUNT * flowHeight * 0.5;
			worldPos.y   += offset;

			gl_Position   = worldToClip(worldPos);

		}
	
	#endif

	#ifdef RAIN_PUDDLES

		if (rainPuddle > 1e-10) {

			vec3 worldPos = getWorld();

			blockCoords = floor(worldPos.xz + 0.5);

			puddle  = saturate(lmcoord.y * 32 - 30);                     // Only blocks exposed to sky
			puddle *= saturate(gl_Normal.y);                             // Only blocks facing up
			puddle *= float(mc_Entity.x != 1033 && mc_Entity.x != 1020); // Not Leaves and not lava

			puddle *= saturate(noise(worldPos.xz * RAIN_PUDDLES_SIZE) * RAIN_PUDDLES_DEPTH - (RAIN_PUDDLES_DEPTH * (1 - RAIN_PUDDLES_COVERAGE) - RAIN_PUDDLES_COVERAGE)); // Puddles
			puddle *= saturate(gl_Color.a * 3 - 2);                      // No puddle in cavities
			puddle *= rainPuddle;                                        // Rain

		}

	#endif

}