#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/lib/time.glsl"
#include "/core/kernels.glsl"

uniform float  frameTimeCounter;

#if defined HDR_EMISSIVES || defined WAVING_BLOCKS || defined WAVING_LIQUIDS || defined RAIN_PUDDLES
	#include "/lib/vertex_transform.glsl"
#else
	#include "/lib/vertex_transform_simple.glsl"
#endif

#if defined WAVING_BLOCKS || defined WAVING_LIQUIDS

	vec3 wavyChaotic(vec3 worldPos, float amount, float speed) {
		vec2 seed = time * vec2(1.5 * speed, -2. * speed);
		seed     += worldPos.xz + (worldPos.y * 0.25);
		vec2 XZ   = sin(seed) * amount;
		return vec3(XZ.x, -1e-3, XZ.y);
	}

	vec3 wavySineY(vec3 worldPos, float amount, float speed) {
		float seed = dot(worldPos, vec3(0.5, 0.1, 0.5)) + (time * speed);
		return vec3(0, sin(seed) * amount, 0);
	}

#endif

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;

out vec2 lmcoord;
out vec2 basecoord;
out vec4 glcolor;
out vec3 viewPos;

flat out int mcEntity;

flat out vec2 spriteSize;
flat out vec2 midTexCoord;

#if defined DIRECTIONAL_LIGHTMAPS || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
attribute vec4 at_tangent;
flat out  mat3 tbn;
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
uniform float rainPuddle;
out     float puddle;
out     vec2  blockCoords;
#endif

#ifdef BLINKING_ORES
flat out float oreBlink;
#endif


void main() {
	gl_Position = getPosition();
	basecoord   = getCoord();
	lmcoord 	= getLmCoord();
	glcolor 	= gl_Color;
	viewPos 	= getView();

	mcEntity    = int(max(0,mc_Entity.x));
	int blockId = getID(mcEntity);

	spriteSize  = abs(basecoord - mc_midTexCoord.xy);
	midTexCoord = mc_midTexCoord.xy;

#if defined DIRECTIONAL_LIGHTMAPS || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)

	tbn = getTBN(at_tangent);

#endif

#ifdef DIRECTIONAL_LIGHTMAPS

	directionalLightmapStrength = 1.0;
	if      (blockId == 2  || blockId == 17) directionalLightmapStrength = 0;
	else if (blockId == 20 || blockId == 21 || blockId == 15) directionalLightmapStrength = 0.25;
	else if (blockId >= 10 && blockId <= 13 || blockId == 16) directionalLightmapStrength = 0.5;

#endif

#if defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)

	glNormal = gl_Normal;

#endif

#if defined HDR_EMISSIVES || defined WAVING_BLOCKS || defined WAVING_LIQUIDS || defined RAIN_PUDDLES

	vec3 worldPos = getWorld();

#endif

#ifdef HDR_EMISSIVES

	worldPosY = worldPos.y;

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
	if ( ( blockId == 10 || blockId == 11
	#ifdef WAVING_FIRE
		|| blockId == 17
	#endif
	) && basecoord.y < mc_midTexCoord.y) { 

		vec3 wPos   = worldPos;
		vec3 offset = wavyChaotic(wPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

		wPos       += offset;
		gl_Position = worldToClip(wPos);

	}

#ifdef WAVING_LANTERNS
	// Waving Lanterns
	else if (blockId == 15) {

		vec3 wPos   = worldPos;
		vec3 offset = wavyChaotic(wPos, (WAVING_BLOCKS_AMOUNT * 0.3), WAVING_BLOCKS_SPEED);

		wPos        += offset * (1 - fract(wPos.y - 0.01));
		gl_Position = worldToClip(wPos);

	}
#endif

	// Waving Blocks All Vertices
	else if (blockId == 12     // Upper section of 2-Tall plants
	#ifdef WAVING_LEAVES
		|| blockId == 13  // Leaves
	#endif
	) {

		vec3 wPos   = worldPos;
		vec3 offset = wavyChaotic(wPos, WAVING_BLOCKS_AMOUNT, WAVING_BLOCKS_SPEED);

		wPos       += offset;
		gl_Position = worldToClip(wPos);

	}

#ifdef WAVING_LILYPADS
	else if (blockId == 17) {

		vec3  wPos   = worldPos;
		float offset = wavySineY(wPos, WAVING_LIQUIDS_AMOUNT, WAVING_LIQUIDS_SPEED * 2).y;

		wPos.y     += offset;
		gl_Position = worldToClip(wPos);

	}
#endif

#endif

#ifdef WAVING_LIQUIDS

	// Waving Liquids
	if (blockId == 2) {

		vec3  wPos       = worldPos;
		float flowHeight = fract(wPos.y + 0.01);

		float offset  = wavySineY(wPos, WAVING_LIQUIDS_AMOUNT * flowHeight, WAVING_LIQUIDS_SPEED).y;
		offset       -= WAVING_LIQUIDS_AMOUNT * flowHeight * 0.5;
		wPos.y       += offset;

		gl_Position   = worldToClip(wPos);

	}

#endif

#ifdef RAIN_PUDDLES

	if (rainPuddle > 1e-10) {

		vec3 wPos = worldPos;

		blockCoords = floor(wPos.xz + 0.5);

		puddle  = saturate(lmcoord.y * 32 - 30);                     // Only blocks exposed to sky
		puddle *= saturate(gl_Normal.y * 0.5 + 0.5);                 // Only blocks facing up
		puddle *= float(blockId != 13 && blockId != 2);              // Not Leaves and not lava

		puddle *= saturate(noise(wPos.xz * RAIN_PUDDLE_SIZE) * RAIN_PUDDLE_OPACITY - (RAIN_PUDDLE_OPACITY * (1 - RAIN_PUDDLE_COVERAGE) - RAIN_PUDDLE_COVERAGE)); // Puddles
		puddle *= saturate(gl_Color.a * 3 - 2);                      // No puddle in cavities
		puddle *= rainPuddle;                                        // Rain

	}

#endif
}