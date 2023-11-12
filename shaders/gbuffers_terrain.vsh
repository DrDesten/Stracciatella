#if ! defined INCLUDE_GBUFFERS_TERRAIN_VSH
#define INCLUDE_GBUFFERS_TERRAIN_VSH

#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#if ! defined INCLUDE_UNIFORM_float_frameTimeCounter
#define INCLUDE_UNIFORM_float_frameTimeCounter
uniform float frameTimeCounter; 
#endif
#if defined WAVING_BLOCKS || defined WAVING_LIQUIDS || defined RAIN_PUDDLES
	#include "/lib/vertex_transform.glsl"
#else
	#include "/lib/vertex_transform_simple.glsl"
#endif

#if defined WAVING_BLOCKS || defined WAVING_LIQUIDS

	#ifdef WORLD_TIME_ANIMATION
#if ! defined INCLUDE_UNIFORM_int_worldTime
#define INCLUDE_UNIFORM_int_worldTime
uniform int worldTime; 
#endif
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

#endif

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;

out vec2 lmcoord;
out vec2 basecoord;
out vec4 glcolor;
out vec3 viewPos;

#if defined DIRECTIONAL_LIGHTMAPS || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
attribute vec4 at_tangent;
flat out  mat3 tbn;
#endif

#if defined DIRECTIONAL_LIGHTMAPS || defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
flat out vec2  spriteSize;
flat out vec2  midTexCoord;
#endif

#ifdef DIRECTIONAL_LIGHTMAPS
flat out float directionalLightmapStrength;
#endif

#if defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
flat out vec3 glNormal;
#endif

#ifdef HDR_EMISSIVES
out float worldPosY;
#endif

#ifdef RAIN_PUDDLES
#if ! defined INCLUDE_UNIFORM_float_rainPuddle
#define INCLUDE_UNIFORM_float_rainPuddle
uniform float rainPuddle; 
#endif
out     float puddle;
out     vec2  blockCoords;
#endif

#ifdef BLINKING_ORES
flat out float oreBlink;
#endif

flat out int mcEntity;

void main() {
	gl_Position = ftransform();
	basecoord   = getCoord();
	lmcoord 	= getLmCoord();
	glcolor 	= gl_Color;
	viewPos 	= getView();

	mcEntity    = int(max(0,mc_Entity.x));
	int blockId = getID(mcEntity);

#if defined DIRECTIONAL_LIGHTMAPS || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)

	tbn = getTBN(at_tangent);

#endif

#if defined DIRECTIONAL_LIGHTMAPS || defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)

	spriteSize  = abs(basecoord - mc_midTexCoord.xy);
	midTexCoord = mc_midTexCoord.xy;

#endif

#ifdef DIRECTIONAL_LIGHTMAPS

	directionalLightmapStrength = 1.0;
	if      (blockId == 2  || blockId == 16) directionalLightmapStrength = 0;
	else if (blockId == 20 || blockId == 21 || blockId == 14) directionalLightmapStrength = 0.25;
	else if (blockId >= 10 && blockId <= 13 || blockId == 15) directionalLightmapStrength = 0.5;

#endif

#if defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)

	glNormal = gl_Normal;

#endif

#ifdef HDR_EMISSIVES

	worldPosY = getWorld().y;

#endif

#ifdef BLINKING_ORES

	oreBlink = sin(frameTimeCounter * 3) * 0.5 + 0.5;

	switch (int(blockId + 0.5)) {

		#ifdef BLINKING_ORES_DIAMOND
			case 40: break;
		#endif
		#ifdef BLINKING_ORES_ANCIENT_DEBRIS
			case 41: break;
		#endif
		#ifdef BLINKING_ORES_IRON
			case 42: break;
		#endif
		#ifdef BLINKING_ORES_GOLD
			case 43: break;
		#endif
		#ifdef BLINKING_ORES_COPPER
			case 44: break;
		#endif
		#ifdef BLINKING_ORES_REDSTONE
			case 45: break;
		#endif
		#ifdef BLINKING_ORES_LAPIS
			case 46: break;
		#endif
		#ifdef BLINKING_ORES_EMERALD
			case 47: break;
		#endif
		#ifdef BLINKING_ORES_COAL
			case 48: break;
		#endif
		#ifdef BLINKING_ORES_NETHER_QUARTZ
			case 49: break;
		#endif
		#ifdef BLINKING_ORES_NETHER_GOLD
			case 50: break;
		#endif

		default:
			oreBlink = 0;
	}

#endif
	

#ifdef WAVING_BLOCKS

	// Waving Blocks Upper Vertices
	if ((blockId == 10 || blockId == 11
	#ifdef WAVING_FIRE
	|| blockId == 16
	#endif
	) && basecoord.y < mc_midTexCoord.y) { 

		vec3 worldPos = getWorld();
		vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

		worldPos     += offset;

		gl_Position   = worldToClip(worldPos);

	}

	#ifdef WAVING_LANTERNS

	// Waving Lanterns
	else if (blockId == 14) {

		vec3 worldPos = getWorld();
		vec3 offset   = wavyChaotic(worldPos, (WAVING_BLOCKS_AMOUNT * 0.3), WAVING_BLOCKS_SPEED);

		worldPos     += offset * (1 - fract(worldPos.y - 0.01));

		gl_Position   = worldToClip(worldPos);

	}

	#endif

	// Waving Blocks All Vertices
	else if (blockId == 12     // Upper section of 2-Tall plants
	#ifdef WAVING_LEAVES
		|| blockId == 13  // Leaves
	#endif
	) {

		vec3 worldPos = getWorld();
		vec3 offset   = wavyChaotic(worldPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

		worldPos     += offset;

		gl_Position   = worldToClip(worldPos);

	}

	#ifdef WAVING_LILYPADS

	else if (blockId == 15) {

		vec3  worldPos  = getWorld();

		float offset  = wavySineY(worldPos, WAVING_LIQUIDS_AMOUNT, WAVING_LIQUIDS_SPEED * 2).y;
		worldPos.y   += offset;

		gl_Position   = worldToClip(worldPos);

	}
	
	#endif

#endif

#ifdef WAVING_LIQUIDS

	// Waving Liquids
	if (blockId == 2) {

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
		puddle *= saturate(gl_Normal.y * 0.5 + 0.5);                             // Only blocks facing up
		puddle *= float(blockId != 13 && blockId != 2);              // Not Leaves and not lava

		puddle *= saturate(noise(worldPos.xz * RAIN_PUDDLE_SIZE) * RAIN_PUDDLE_OPACITY - (RAIN_PUDDLE_OPACITY * (1 - RAIN_PUDDLE_COVERAGE) - RAIN_PUDDLE_COVERAGE)); // Puddles
		puddle *= saturate(gl_Color.a * 3 - 2);                      // No puddle in cavities
		puddle *= rainPuddle;                                        // Rain

	}

#endif
}

#endif