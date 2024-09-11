#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/core/transform.glsl"
#include "/lib/sky.glsl"
#include "/lib/colored_lights.glsl"

#include "/core/dh/uniforms.glsl"
#include "/core/dh/textures.glsl"
#include "/core/dh/transform.glsl"

uniform sampler2D colortex1;

#if (defined FOG || defined CAVE_SKY) && defined OVERWORLD
uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3 sunDir;

#ifdef CUSTOM_STARS
#include "/lib/stars.glsl"
#endif

uniform float frameTimeCounter;
#include "/lib/lightmap.glsl"
uniform float customLightmapBlend;

#ifdef COLORED_LIGHTS
const bool colortex4MipmapEnabled = true;
uniform sampler2D colortex4; 
#if defined DEBUG && DEBUG_MODE == 2
uniform sampler2D colortex5;
#endif
#endif

flat in vec4 handLight;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;
float KleinNishina(float cosTheta, float e) {
    // For clouds, e has to be around 700-1000
    return e / (2.0 * PI * (e * (1.0 - cosTheta) + 1.0) * log(2.0 * e + 1.0));
}
vec4 getLightmap(vec2 coord) {
    return vec2x16to4(texture(colortex1, coord).xy);
}
vec3 getColor(vec3 color) {
	return sq(oklab2rgb(vec3(1, color.yz)));
}

/* DRAWBUFFERS:0 */
layout(location = 0) out vec4 FragOut0;
void main() {
	float depth     = getDepth(coord);
	vec3  screenPos = vec3(coord, depth);
	vec3  viewPos   = toView(screenPos * 2 - 1);
	vec3  viewDir   = normalize(viewPos);
	vec3  playerPos = toPlayer(viewPos);
	vec3  playerDir = normalize(playerPos);

#ifdef DISTANT_HORIZONS
	float dhDepth     = getDepthDH(coord);
	vec3  dhScreenPos = vec3(coord, dhDepth);
	vec3  dhViewPos   = screenToViewDH(dhScreenPos);
	vec3  dhPlayerPos = toPlayer(dhViewPos);

	vec3  combinedViewPos   = depth < 1 ? viewPos : dhViewPos;
	vec3  combinedPlayerPos = depth < 1 ? playerPos : dhPlayerPos;
#else
	vec3  combinedViewPos   = viewPos;
	vec3  combinedPlayerPos = playerPos;
#endif

	vec4 skyGradient = getSkyColor_fogArea(viewDir);

#ifdef OVERWORLD
#ifdef CUSTOM_STARS

	vec4 stars      = getStars(playerDir, 1 - skyGradient.a);
	stars.a        *= saturate(abs(dot(viewDir, sunDir)) * -200 + 199);
	skyGradient.rgb = mix(skyGradient.rgb, stars.rgb, stars.a);

#endif
#endif

	vec3 color = getAlbedo(coord);

#ifndef DISTANT_HORIZONS
	bool isSky = depth >= 1;
#else
	bool isSky = depth >= 1 && dhDepth >= 1;
#endif
	if (isSky) { 

#ifdef OVERWORLD

		color += skyGradient.rgb;

		#ifdef CAVE_SKY
		float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(cameraPosition.y * 0.25 - (CAVE_SKY_HEIGHT * 0.25)) );
		color = mix(fogCaveColor, color, cave);
		#endif

#else

		color = skyGradient.rgb;

#endif

#ifdef CUSTOM_CLOUDS

		if (playerDir.y > 0) {

		float fadeDistance   = 6e3;
		float cloudHeight    = 100;
		float cloudThickness = 2;

		float coverageShift = 0;
		float coarseScale   = 1/100.;

		float cloudDistance      = cloudHeight / playerDir.y;
		float cloudFade          = exp2(-cloudDistance / fadeDistance);
		vec2  cloudCoords        = (playerDir.xz * cloudDistance + cameraPosition.xz) * coarseScale;
		
		float density            = sin(frameTimeCounter) * 0.35 + 0.4;
		float detailScale        = 10;
		float perspectiveDensity = 1 - exp2(-log2(1 - density) / playerDir.y);

		vec2  offsetRange = playerDir.xz * -min(cloudThickness / playerDir.y, 1.5);
		float offset      = 1;
		
		float sampleHeight; // 2 Refinement Iterations
		sampleHeight = pnoise(cloudCoords + offsetRange * offset);
		offset       = sampleHeight;
		sampleHeight = pnoise(cloudCoords + offsetRange * offset);
		offset       = sampleHeight;
		cloudCoords += offsetRange * offset;

		vec2  cce = vec2(1e-1, 0);
		float cc0 = pnoise(cloudCoords);
		float ccX = pnoise(cloudCoords + cce.xy);
		float ccZ = pnoise(cloudCoords + cce.yx);
		vec3  cloudNormal = normalize(vec3(ccX - cc0, cce.x, ccZ - cc0));

		float cloudCoverage = cc0;
		cloudCoverage       = sigmoidNorm(cloudCoverage + coverageShift - 0.5); 
		cloudThickness      = cloudCoverage * cloudThickness * 2;

		// Lighting

		float cloudBrightness = 0;

		vec3  sunDirPlayerEye    = toPlayerEye(sunDir);
        float sunDotView         = dot(sunDir, viewDir);
        float volumeAlongRay     = sq(cloudThickness) * (abs(sunDotView) * (2 - HALF_PI) + HALF_PI); // How thick is the cloud along the view ray in direction to the light source
        float visibilityAlongRay = exp(-volumeAlongRay);
        float visibility         = exp(-cloudThickness);
        float diffuseCloud       = dot(sunDirPlayerEye, cloudNormal);
		
		float anisotropicScatter = KleinNishina(sunDotView, 800) * visibilityAlongRay;
		float interpolator       = smootherstep(-diffuseCloud);
		float densityMixFactor   = visibility * (1 - interpolator) + interpolator;
		cloudBrightness         += (
			(diffuseCloud * -0.5 + 0.5) * densityMixFactor +
			anisotropicScatter
		);

		color = mix(color, vec3(cloudBrightness), cloudCoverage * cloudFade);
		//color = cloudNormal * .5 + .5;
		color = vec3(diffuseCloud);

		}

#endif

	} else {

		vec4 lmcoord = getLightmap(coord);

#ifdef COLORED_LIGHTS

		vec3  rawColoredLight      = textureBicubic(colortex4, coord, LIGHTMAP_COLOR_RES, 1/LIGHTMAP_COLOR_RES).rgb;
		vec3  blockLightColor      = oklab2rgb(rawColoredLight);
		float blockLightImportance = rawColoredLight.x;
		
		//blockLightColor *= pow(-sq(blockLightImportance) + 2 * blockLightImportance, 1./4);
		blockLightColor  = blockLightColor / (maxc(blockLightColor) + 0.0025);
		blockLightColor  = saturate(applySaturation(blockLightColor, 0.5));
		blockLightColor  = saturate(applyVibrance(blockLightColor, LIGHTMAP_COLOR_VIBRANCE));

		float dist = sqmag(playerPos);
		#ifdef IS_IRIS

		float falloff = smoothstep(0.05, 1, exp2( -dist * 0.03 / handLight.a ));
		blockLightColor = blockLightColor + handLight.rgb * falloff;
		blockLightColor = mix(blockLightColor, handLight.rgb, falloff);
		lmcoord.x = max(lmcoord.x, falloff * handLight.a);

		#else

		float handLightBrightness = smoothstep(handLight.a * 25, 0, dist);
		float handLightBrightnessExp = exp(-sq(dist / handLight.a * 15));
		blockLightColor = blockLightColor + handLight.rgb * handLightBrightness;
		blockLightColor = mix(blockLightColor, handLight.rgb, handLightBrightnessExp);

		#endif

		#ifndef DEBUG

			color *= getCustomLightmap(lmcoord.xyz, customLightmapBlend, blockLightColor) * (1 - lmcoord.a) + lmcoord.a;

		#elif DEBUG_MODE == 2

			switch (DEBUG_COLORED_LIGHTS_MODE) {
			case 0: { // Mix Color

				color = mix(color, blockLightColor * (1 - lmcoord.a) + lmcoord.a, 0.666);
				vec3 tmp = texture(colortex5, coord).rgb;
				if (sum(tmp) != 0) color = tmp;

				break;
			}
			case 1: { // Mix Age
				
				color = mix(color, vec3(luminance(blockLightColor)), 0.666);
				vec3 tmp = texture(colortex5, coord).rgb;
				if (sum(tmp) != 0) color = tmp;

				break;
			}
			case 2: { // Pure Color

				color = blockLightColor * (1 - lmcoord.a) + lmcoord.a;

				break;
			}
			case 3: { // Source Color
				
				vec3 tmp = texture(colortex5, coord).rgb;
				if (tmp != vec3(0)) color = tmp;
				else color *= 1 - DEBUG_BLEND;

				break;
			}
			}

		#endif

#else
		
		color *= getCustomLightmap(lmcoord.xyz, customLightmapBlend) * (1 - lmcoord.a) + lmcoord.a;

#endif

#if FOG != 0

	float fog = fogFactorTerrain(combinedPlayerPos);

	#if FOG_ADVANCED && defined OVERWORLD 
	float fa = fogFactorAdvanced(viewDir, combinedPlayerPos);
	fog      = max(fog, fa);
	#endif

	#if defined OVERWORLD && defined CAVE_FOG
		float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
		cave       = saturate( cave + float(cameraPosition.y > 512) );
		color = mix(color, mix(fogCaveColor, skyGradient.rgb, cave), fog);
	#else
		color = mix(color, skyGradient.rgb, fog);
	#endif
		
#endif

	}

#if DITHERING >= 1
	color += ditherColor(gl_FragCoord.xy);
#endif
	FragOut0 = vec4(color, 1.0); //gcolor
}

/*
#ifdef CAVE_FOG
dummy
#endif
*/