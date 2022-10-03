#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;
in vec3 viewPos;

#ifdef DIRECTIONAL_LIGHTMAPS
	uniform ivec2 atlasSize;
	flat in vec2  spriteSize;
	flat in vec2  midTexCoord;
	flat in mat2  tbn;
	flat in float directionalLightmapStrength;
#elif defined HDR_EMISSIVES
	flat in vec2 spriteSize;
	flat in vec2 midTexCoord;
#endif
#ifdef HDR_EMISSIVES
	flat in vec3 rawNormal;
#endif
#if NORMAL_TEXTURE_MODE == 1 && defined MC_NORMAL_MAP && defined DIRECTIONAL_LIGHTMAPS 
	uniform sampler2D normals;
#endif

#ifdef RAIN_PUDDLES
	uniform sampler2D colortex4;
	uniform float frameTimeCounter;
	uniform float rainPuddle;
	in float puddle;
	in vec2  blockCoords;
#endif

uniform float customLightmapBlend;

#ifdef BLINKING_ORES
	flat in float oreBlink;
#endif

flat in int blockId;

float calculateHeight(vec2 coord) {
	float baseHeight = mean(textureLod(gcolor, coord, 100.0).rgb);
	float absHeight  = mean(texture(gcolor, coord).rgb);
	float relHeight  = (absHeight - baseHeight) * 0.5 + 0.5;
	return relHeight;
}
float calculateHeight(vec2 coord, float baseHeight) {
	float absHeight  = mean(texture(gcolor, coord).rgb);
	float relHeight  = absHeight - baseHeight;
	return relHeight;
}
vec2 getBlocklightDir(vec2 lco, mat2 tbn) {
    vec2 blockLightDir = vec2(dFdx(lco.x), dFdy(lco.x));
    return abs(blockLightDir.x) + abs(blockLightDir.y) < 1e-6 ? vec2(0,1) : normalize(tbn * blockLightDir); // By doing matrix * vector, I am using the transpose of the matrix. Since tbn is purely rotational, this inverts the matrix.
}


vec3 crosstalk(vec3 color, float factor) {
	vec3 distribute = vec3(1) - exp(-factor * color);
	color.r += dot(color.gb, distribute.gb);
	color.g += dot(color.rb, distribute.rb);
	color.b += dot(color.rg, distribute.rg);
	return color;
} 


#ifdef COLORED_LIGHTS
/* DRAWBUFFERS:015 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
layout(location = 2) out vec4 FragOut2;
#else
/* DRAWBUFFERS:01 */
layout(location = 0) out vec4 FragOut0;
layout(location = 1) out vec2 FragOut1;
#endif
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb;

	#ifdef RAIN_PUDDLES

		if (rainPuddle > 1e-10) {

			vec2  waterTextureSize   = vec2(textureSize(colortex4, 0));
			float waterTextureAspect = waterTextureSize.x / waterTextureSize.y;
			vec2  waterCoords        = vec2(blockCoords.x, blockCoords.y * waterTextureAspect);
			waterCoords.y           += waterTextureAspect * round(frameTimeCounter * 2);
			vec4  waterTexture       = texture(colortex4, waterCoords);
			waterTexture.rgb         = waterTexture.rgb * vec3(RAIN_PUDDLE_COLOR_R, RAIN_PUDDLE_COLOR_G, RAIN_PUDDLE_COLOR_B);

			color.rgb = mix(color.rgb, waterTexture.rgb, puddle * waterTexture.a);

		}

	#endif

	#ifdef DIRECTIONAL_LIGHTMAPS

		#if NORMAL_TEXTURE_MODE == 1  && defined MC_NORMAL_MAP

			vec3 normal = texture(normals, coord).xyz * 2 - 1;
			normal.z    = sqrt(saturate(1 - dot(normal.xy, normal.xy)));

		#else

			// NORMAL MAP GENERATION ////////////////////////////////
			vec2  atlasPixel = (1. / GENERATED_NORMALS_RESOLUTION_MULTIPLIER) / atlasSize;
			float relHeightN = mean( texture(gcolor, clamp(coord + vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
			float relHeightS = mean( texture(gcolor, clamp(coord - vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
			float relHeightE = mean( texture(gcolor, clamp(coord + vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
			float relHeightW = mean( texture(gcolor, clamp(coord - vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
			
			vec3  normal = normalize(vec3(relHeightW - relHeightE, relHeightS - relHeightN, 0.3333));
			
		#endif

		// DIRECTIONAL LIGHTMAPS ////////////////////////////////
		vec2 blockLightDir = getBlocklightDir(lmcoord, tbn);
		vec3 lightingDir   = normalize( vec3(blockLightDir, 0.5 + sq(sq(lmcoord.x))) ); // The closer to the light source, the "higher" the light is

		float diffuse = dot(normal, lightingDir) * (DIRECTIONAL_LIGHTMAPS_STRENGTH * 0.5) + (0.5 * (1 - DIRECTIONAL_LIGHTMAPS_STRENGTH) + 0.5);
		diffuse       = diffuse * directionalLightmapStrength + (1 - directionalLightmapStrength);

	#endif


	#ifdef HDR_EMISSIVES

		// Adds an HDR effect to Emissive blocks. Works by boosting the brightness of emissive parts of blocks and the applying tonemapping to avoid clipping.

		bool white  = blockId == 40 || blockId == 36 || blockId == 20;
		bool orange = blockId == 41;
		bool red    = blockId == 42;
		bool blue   = blockId == 43;
		bool purple = blockId == 44;
		bool anyCol = blockId == 45 || blockId == 34;
		bool anyLow = blockId == 46;
		bool candle = blockId == 47;

		const vec3 hsvBrown = vec3(39./360, .5, .5);

		float emissiveness = 0;
		bool  isEmissive   = white || anyCol || anyLow || orange || red || blue || purple || candle;
		if (isEmissive) {

			vec3  hsv       = rgb2hsv(color.rgb);
			float brownness = saturate(sqmag((hsvBrown - hsv) * vec3(10,3,2)) * 2 - 1);
			
			if      (white)  emissiveness = saturate(hsv.z * 2 - 1);
			else if (anyCol) emissiveness = saturate(max(saturate(hsv.y * 2 - 0.5), saturate(hsv.z * 2 - 1)) * 2 - 0.5);
			else if (anyLow) emissiveness = saturate(0.75 * hsv.z * hsv.z);
			else if (orange) emissiveness = saturate(peak05(fract(hsv.x + 0.45)) * 2 - 1) * saturate(hsv.z * 3 - 2);
			else if (red)    emissiveness = saturate(brownness * 1.25 - .25) + saturate(hsv.z * 4 - 3);
			else if (blue)   emissiveness = saturate(sqmag((vec3(0.57, .8, .8) - hsv) * vec3(2,2,2)) * -1 + 1) + saturate(hsv.y * -5 + 4) * saturate(hsv.z * 5 - 4) * brownness;
			else if (purple) emissiveness = saturate(hsv.z * 1.5 - .5) * saturate(hsv.y * 3 - 2) + sq(saturate(hsv.z * 5 - 4));
			else if (candle) emissiveness = sqsq(saturate((midTexCoord.y - coord.y) * (0.5 / spriteSize.y) + 0.5 + saturate(rawNormal.y)));

			color.rgb  = reinhard_sqrt_tonemap_inverse(color.rgb * 0.996, 0.5);
			color.rgb += (emissiveness * HDR_EMISSIVES_BRIGHTNESS * 1.5) * color.rgb;

		}

		#define coloredLightEmissive float(isEmissive) * blockLightEmissiveColor
		
	#else

	 	#define emissiveness 0
		#define coloredLightEmissive float(blockId == 20 || blockId == 36 || blockId == 34 || (blockId >= 40 && blockId <= 47)) * blockLightEmissiveColor

	#endif

	#ifdef COLORED_LIGHTS
		vec3 blockLightEmissiveColor;
		switch (blockId) {
			case 41:
				blockLightEmissiveColor = LIGHTMAP_COLOR_ORANGE; // Orange
				break;
			case 42:
				blockLightEmissiveColor = LIGHTMAP_COLOR_RED; // Red
				break;
			case 43:
				blockLightEmissiveColor = LIGHTMAP_COLOR_BLUE; // Blue
				break;
			case 44:
				blockLightEmissiveColor = LIGHTMAP_COLOR_PURPLE; // Purple
				break;
			default:
				blockLightEmissiveColor = color.rgb; // Keep Color (all other id's)
		}
		//blockLightEmissiveColor *= lmcoord.x;
	#endif

	#ifdef DIRECTIONAL_LIGHTMAPS
		vec2 lightmapCoord = vec2(lmcoord.x * diffuse, lmcoord.y);
	#else
		// Should just replace the variable name
		#define lightmapCoord lmcoord
	#endif

	#ifdef HDR_EMISSIVES
		if (isEmissive) color.rgb = reinhard_sqrt_tonemap(color.rgb, 0.5);
	#endif

	#ifdef BLINKING_ORES
		color.rgb = mix(color.rgb, sqrtf01(color.rgb) * 0.9 + 0.1, oreBlink * BLINKING_ORES_BRIGHTNESS);
	#endif

	#if DITHERING >= 2
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif

	FragOut0 = color;
    if (FragOut0.a < 0.1) discard;
	FragOut1 = encodeLightmapData(vec4(lightmapCoord, glcolor.a, saturate(emissiveness)));
	#ifdef COLORED_LIGHTS
	FragOut2 = vec4(coloredLightEmissive, 1);
	#endif
}