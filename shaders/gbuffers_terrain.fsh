#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"

#include "/lib/fog_sky.glsl"

#ifdef FOG

	uniform mat4  gbufferModelViewInverse;
	uniform vec3  fogColor;
	uniform int   isEyeInWater;
	uniform float far;

	#ifdef CUSTOM_SKY
		uniform float daynight;
		uniform float rainStrength;
	#endif

	#if FOG_QUALITY == 1

		uniform vec3  sunDir;
		uniform vec3  up;
		uniform float sunset;
		uniform vec3  skyColor;
		uniform ivec2 eyeBrightnessSmooth;

	#endif

#endif

varying vec2 lmcoord;
varying vec2 coord;
varying vec4 glcolor;
varying vec3 viewPos;

#ifdef DIRECTIONAL_LIGHTMAPS
	uniform ivec2 atlasSize;
	varying vec2  spriteSize;
	varying vec2  midTexCoord;
	varying mat2  tbn;
	varying float directionalLightmapStrength;
#endif
#if NORMAL_TEXTURE_MODE == 1 && defined DIRECTIONAL_LIGHTMAPS
	uniform sampler2D normals;
#endif

#ifdef RAIN_PUDDLES
	uniform sampler2D colortex4;
	uniform float     frameTimeCounter;
	uniform float     rainPuddle;
	varying float     puddle;
	varying vec2      blockCoords;
#endif

#ifdef CUSTOM_LIGHTMAP
	uniform float customLightmapBlend;
#endif

#ifdef BLINKING_ORES
	varying float oreBlink;
#endif

float calculateHeight(vec2 coord) {
	float baseHeight = mean(texture2DLod(texture, coord, 100.0).rgb);
	float absHeight  = mean(texture2D(texture, coord).rgb);
	float relHeight  = (absHeight - baseHeight) * 0.5 + 0.5;
	return relHeight;
}
float calculateHeight(vec2 coord, float baseHeight) {
	float absHeight  = mean(texture2D(texture, coord).rgb);
	float relHeight  = absHeight - baseHeight;
	return relHeight;
}
vec2 getBlocklightDir(vec2 lco, mat2 tbn) {
    vec2 blockLightDir = vec2(dFdx(lco.x), dFdy(lco.x));
    return abs(blockLightDir.x) + abs(blockLightDir.y) < 1e-6 ? vec2(0,1) : normalize(tbn * blockLightDir); // By doing matrix * vector, I am using the transpose of the matrix. Since tbn is purely rotational, this inverts the matrix.
}

/* DRAWBUFFERS:0 */
void main() {
	vec4 color = getAlbedo(coord);
	color.rgb *= glcolor.rgb;

	#ifdef RAIN_PUDDLES

		if (rainPuddle > 1e-10) {

			vec2  waterTextureSize   = vec2(textureSize(colortex4, 0));
			float waterTextureAspect = waterTextureSize.x / waterTextureSize.y;
			vec2  waterCoords        = vec2(blockCoords.x, blockCoords.y * waterTextureAspect);
			waterCoords.y           += waterTextureAspect * round(frameTimeCounter * 2);
			vec4  waterTexture       = texture2D(colortex4, waterCoords);
			waterTexture.rgb         = waterTexture.rgb * vec3(0.3, 0.4, 0.85);

			color.rgb = mix(color.rgb, waterTexture.rgb, puddle * waterTexture.a);

		}

	#endif

	#ifdef DIRECTIONAL_LIGHTMAPS

		#if NORMAL_TEXTURE_MODE == 0

			// NORMAL MAP GENERATION ////////////////////////////////
			vec2  atlasPixel = (1. / GENERATED_NORMALS_RESOLUTION_MULTIPLIER) / atlasSize;
			float baseHeight = mean(texture2DLod(texture, coord, 100.0).rgb);
			float relHeightN = calculateHeight(  clamp(coord + vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord , baseHeight );
			float relHeightS = calculateHeight(  clamp(coord - vec2(0, atlasPixel.y) - midTexCoord, -spriteSize, spriteSize) + midTexCoord , baseHeight );
			float relHeightE = calculateHeight(  clamp(coord + vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord , baseHeight );
			float relHeightW = calculateHeight(  clamp(coord - vec2(atlasPixel.x, 0) - midTexCoord, -spriteSize, spriteSize) + midTexCoord , baseHeight );
			
			vec3  normal = normalize(vec3(relHeightW - relHeightE, relHeightS - relHeightN, 0.3333));

		#elif NORMAL_TEXTURE_MODE == 1

			vec3 normal = texture2D(normals, coord).xyz * 2 - 1;
			normal.z    = sqrt(1 - dot(normal.xy, normal.xy));

		#endif

		// DIRECTIONAL LIGHTMAPS ////////////////////////////////
		vec2 blockLightDir = getBlocklightDir(lmcoord, tbn);
		vec3 lightingDir   = normalize( vec3(blockLightDir, 1 + sq(sq(lmcoord.x))) ); // The closer to the light source, the "higher" the light is

		float diffuse = dot(normal, lightingDir) * (DIRECTIONAL_LIGHTMAPS_STRENGTH * 0.5) + (0.5 * (1 - DIRECTIONAL_LIGHTMAPS_STRENGTH) + 0.5);
		diffuse       = diffuse * directionalLightmapStrength + (1 - directionalLightmapStrength);

	#endif

	#ifdef CUSTOM_LIGHTMAP

		#ifdef DIRECTIONAL_LIGHTMAPS
		color.rgb *= getCustomLightmap(lmcoord * vec2(diffuse, 1), customLightmapBlend, glcolor.a);
		#else
		color.rgb *= getCustomLightmap(lmcoord, customLightmapBlend, glcolor.a);
		#endif

	#else

		#ifdef DIRECTIONAL_LIGHTMAPS
		color.rgb *= getLightmap(lmcoord * vec2(diffuse, 1)) * glcolor.a;
		#else
		color.rgb *= getLightmap(lmcoord) * glcolor.a;
		#endif

	#endif

	#ifdef BLINKING_ORES
	
		color.rgb = mix(color.rgb, sqrt(color.rgb) * 0.9 + 0.1, oreBlink * BLINKING_ORES_BRIGHTNESS);

	#endif

	#ifdef FOG

		float fog = fogFactor(viewPos, far, gbufferModelViewInverse);

		#if FOG_QUALITY == 1

			#ifdef OVERWORLD
				float cave = saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25);
			#else
				float cave = 1;
			#endif
			
			#ifndef CUSTOM_SKY
				color.rgb  = mix(color.rgb, mix(fogColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, isEyeInWater), cave), fog);
			#else
				color.rgb  = mix(color.rgb, mix(fogColor, getFogSkyColor(normalize(viewPos), sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight, isEyeInWater), cave), fog);
			#endif

		#else

			#if defined FOG_CUSTOM_COLOR && !defined NETHER
				color.rgb = mix(color.rgb, getCustomFogColor(rainStrength, daynight), fog);
			#else
				color.rgb = mix(color.rgb, fogColor, fog);
			#endif

		#endif

	#endif

	//color.rgb = normal * 0.5 + 0.5;

	#if DITHERING >= 1
		color.rgb += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = color; //gcolor
}