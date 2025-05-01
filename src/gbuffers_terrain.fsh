#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/palette.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/core/transform.glsl"

uniform float customLightmapBlend;
uniform float far;

in vec2 lmcoord;
in vec2 basecoord;
in vec4 glcolor;
in vec3 viewPos;

flat in int mcEntity;

flat in vec2 spriteSize;
flat in vec2 midTexCoord;

#if defined DIRECTIONAL_LIGHTMAPS || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
flat in mat3 tbn;
#endif

#ifdef DIRECTIONAL_LIGHTMAPS
uniform ivec2 atlasSize;
flat in float directionalLightmapStrength;
#endif

#if defined HDR_EMISSIVES || (defined RAIN_PUDDLES && defined RAIN_PUDDLE_PARALLAX)
flat in vec3 glNormal;
#endif

#ifdef HDR_EMISSIVES
in float worldPosY;
#endif

#if NORMAL_TEXTURE_MODE == 1 && defined MC_NORMAL_MAP && defined DIRECTIONAL_LIGHTMAPS 
uniform sampler2D normals;
#endif

#ifdef RAIN_PUDDLES
#include "/lib/time.glsl"
uniform sampler2D colortex4;
uniform float     rainPuddle;
in      float     puddle;
in      vec2      blockCoords;
#endif

#ifdef BLINKING_ORES
flat in float oreBlink;
#endif


float calculateHeight(vec2 coord) {
	float baseHeight = avg(textureLod(gcolor, coord, 100.0).rgb);
	float absHeight  = avg(texture(gcolor, coord).rgb);
	float relHeight  = (absHeight - baseHeight) * 0.5 + 0.5;
	return relHeight;
}
float calculateHeight(vec2 coord, float baseHeight) {
	float absHeight  = avg(texture(gcolor, coord).rgb);
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
	
#if defined DISTANT_HORIZONS
#ifdef DH_DISCARD_SMOOTH
	float playerDistSq    = sqmag(toPlayer(viewPos).xz);
	float playerDistBlend = smoothstep(far*far * 0.75, far*far, playerDistSq);
	if (Bayer4(gl_FragCoord.xy) < playerDistBlend) discard;
#endif
#endif

	vec2 coord = basecoord;

#ifdef RAIN_PUDDLES
#ifdef RAIN_PUDDLE_PARALLAX

	if (glNormal.y > 0.9 && rainPuddle > 1e-10) {

		vec3 playerPos           = toPlayer(viewPos);
		#ifdef RAIN_PUDDLE_PARALLAX_REFRACTION
		vec3 refractedPlayerPos  = refract(normalize(playerPos), vec3(0,1,0), 1/1.33);
		vec3 playerDisplacement  = (refractedPlayerPos / refractedPlayerPos.y);
		#else
		vec3 playerDisplacement  = (playerPos / playerPos.y);
		#endif
		vec3 viewDisplacement    = viewPos - backToView(playerPos + playerDisplacement * (RAIN_PUDDLE_PARALLAX_DEPTH * 2));
		vec3 textureDisplacement = viewDisplacement * tbn;

		coord += textureDisplacement.xy * spriteSize * smoothstep(0, 1, puddle);

		coord  = coord - midTexCoord + spriteSize;
		coord /= spriteSize * 2;
		coord  = fract(coord);
		coord *= spriteSize * 2;
		coord  = coord - spriteSize + midTexCoord;

	}

#endif
#endif

	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb;

	blockInfo block = decodeID(mcEntity);

	if (block.id == 10 || block.id == 11) {
		vec2  blockCoords = (coord - midTexCoord + spriteSize) / (spriteSize * 2);
		float ao = 1 - sq(
			(1 - abs(blockCoords.x * 2 - 1)) *
			(blockCoords.y)
		);
		color.rgb *= ao * 0.25 + 0.75;
	}

#ifdef RAIN_PUDDLES

	if (rainPuddle > 1e-10) {

		vec2  waterTextureSize   = vec2(textureSize(colortex4, 0));
		float waterTextureAspect = waterTextureSize.x / waterTextureSize.y;
		vec2  waterCoords        = vec2(blockCoords.x, blockCoords.y * waterTextureAspect);
		waterCoords.y           += waterTextureAspect * round(time * 2);
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
		float relHeightN = avg( texture(gcolor, clamp(coord + vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
		float relHeightS = avg( texture(gcolor, clamp(coord - vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
		float relHeightE = avg( texture(gcolor, clamp(coord + vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
		float relHeightW = avg( texture(gcolor, clamp(coord - vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord).rgb );
		
		vec3  normal = normalize(vec3(relHeightW - relHeightE, relHeightS - relHeightN, 0.3333));
		
	#endif

	// DIRECTIONAL LIGHTMAPS ////////////////////////////////
	vec2 blockLightDir = getBlocklightDir(lmcoord, mat2(tbn));
	vec3 lightingDir   = normalize( vec3(blockLightDir, 0.5 + sq(sq(lmcoord.x))) ); // The closer to the light source, the "higher" the light is

	float diffuse = dot(normal, lightingDir) * (DIRECTIONAL_LIGHTMAPS_STRENGTH * 0.5) + (0.5 * (1 - DIRECTIONAL_LIGHTMAPS_STRENGTH) + 0.5);
	diffuse       = diffuse * directionalLightmapStrength + (1 - directionalLightmapStrength);

#endif


#ifdef HDR_EMISSIVES

	float emissiveness = 0;
	if (block.emissive) {

		// Adds an HDR effect to Emissive blocks. Works by boosting the brightness of emissive parts of blocks and the applying tonemapping to avoid clipping.

		bool white   = block.id == 20 || block.id == 17 || block.id == 2;
		bool orange  = block.id == 21;
		bool red     = block.id == 22;
		bool redPure = block.id == 23;
		bool redOre  = block.id == 45;
		bool blue    = block.id == 24;
		bool purple  = block.id == 25;
		bool anyCol  = block.id == 26 || block.id == 15;
		bool anyLow  = block.id == 27;
		bool candle  = block.id == 28;

		const vec3 hsvBrown = vec3(39./360, .5, .5);

		vec3  hsv       = rgb2hsv(color.rgb);
		float brownness = saturate(sqmag((hsvBrown - hsv) * vec3(10,3,2)) * 2 - 1);
		
		color.rgb  = tm_reinhard_sqrt_inverse(color.rgb * 0.996, 0.5);

		if      (white)   emissiveness = saturate(hsv.z * 2 - 1);
		else if (anyCol)  emissiveness = saturate(max(saturate(hsv.y * 2 - 0.5), saturate(hsv.z * 2 - 1)) * 2 - 0.5);
		else if (anyLow)  emissiveness = saturate(0.75 * hsv.z * hsv.z);
		else if (orange)  emissiveness = saturate(peak05(fract(hsv.x + 0.45)) * 2 - 1) * saturate(hsv.z * 3 - 2);
		else if (red)     emissiveness = saturate(brownness * 1.25 - .25) + saturate(hsv.z * 4 - 3);
		else if (redPure) emissiveness = saturate( saturate( 5 * fract(worldPosY) - 1 ) + saturate( saturate(peak05(fract(hsv.x + .5)) * 2 - 1) * saturate( hsv.y * 2 - 1) ) * 0.5 );
		else if (redOre)  emissiveness = saturate( saturate(sq(peak05(fract(hsv.x + .5)))) * saturate( hsv.y * 2 - 1) * 0.5 );
		else if (blue)    emissiveness = saturate(sqmag((vec3(0.57, .8, .8) - hsv) * vec3(2,2,2)) * -1 + 1) + saturate(hsv.y * -5 + 4) * saturate(hsv.z * 5 - 4) * brownness;
		else if (purple)  emissiveness = saturate(hsv.z * 1.5 - .5) * saturate(hsv.y * 3 - 2) + sq(saturate(hsv.z * 5 - 4));
		else if (candle)  emissiveness = sqsq(saturate((midTexCoord.y - coord.y) * (0.5 / spriteSize.y) + 0.5 + saturate(glNormal.y)));

		color.rgb += (emissiveness * HDR_EMISSIVES_BRIGHTNESS * 1.5) * color.rgb;

	}

	#define coloredLightEmissive float(block.emissive) * blockLightEmissiveColor
	
#else

	float emissiveness = 0;
	#define coloredLightEmissive float(block.emissive) * blockLightEmissiveColor

#endif

#ifdef COLORED_LIGHTS
	vec3 blockLightEmissiveColor;
	if (block.data == 7) {
		blockLightEmissiveColor = color.rgb;
	} else {
		blockLightEmissiveColor = CL_PALETTE[block.data];
	}
#endif

#ifdef DIRECTIONAL_LIGHTMAPS
	vec2 lightmapCoord = vec2(lmcoord.x * diffuse, lmcoord.y);
#else
	// Should just replace the variable name
	#define lightmapCoord lmcoord
#endif

#ifdef HDR_EMISSIVES
	if (block.emissive) color.rgb = tm_reinhard_sqrt(color.rgb, 0.5);
#endif

#ifdef BLINKING_ORES
	color.rgb = mix(color.rgb, sqrtf01(color.rgb) * 0.9 + 0.1, oreBlink * BLINKING_ORES_BRIGHTNESS);
#endif

#if DITHERING >= 2
	color.rgb += ditherColor(gl_FragCoord.xy);
#endif

	FragOut0 = color /* * vec2(saturate( 10 * fract(worldPosY) - 1 ), 1).xxxy */;
	FragOut1 = encodeLightmapData(vec4(lightmapCoord, glcolor.a, saturate(emissiveness)));
	#ifdef COLORED_LIGHTS
	FragOut2 = vec4(coloredLightEmissive, 1);
	#endif
	
#if defined CUTOUT || !defined IS_IRIS
    if (FragOut0.a < 0.1) discard;
#endif
}