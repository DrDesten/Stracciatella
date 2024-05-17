#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"
#include "/lib/sky.glsl"
#include "/lib/colored_lights.glsl"

#include "/core/dh/uniforms.glsl"
#include "/core/dh/textures.glsl"
#include "/core/dh/transform.glsl"

uniform sampler2D colortex1;

#ifdef FOG
	uniform int   isEyeInWater;
	uniform float far;
#endif
#if (defined FOG || defined CAVE_SKY) && defined OVERWORLD
	uniform ivec2 eyeBrightnessSmooth;
#endif

uniform vec3  sunDir;
uniform vec3  up;
uniform vec3  upPosition;
uniform float sunset;
#if defined CUSTOM_SKY
uniform float daynight;
uniform float rainStrength;
#endif

#ifdef CUSTOM_STARS
uniform float normalizedTime;
uniform float customStarBlend;
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

in vec4 handLight;

vec2 coord = gl_FragCoord.xy * screenSizeInverse;

vec2 cubemapCoords(vec3 direction) {
    float l  = max(max(abs(direction.x), abs(direction.y)), abs(direction.z));
    vec3 dir = direction / l;
    vec3 absDir = abs(dir);
    
    vec2 coord;
    if (absDir.x >= absDir.y && absDir.x > absDir.z) {
        if (dir.x > 0) {
            coord = vec2(0, 0.5) + (dir.zy * vec2(1, -1) + 1);
        } else {
            coord = vec2(2.0 / 3, 0.5) + (-dir.zy + 1);
        }
    } else if (absDir.y >= absDir.z) {
        if (dir.y > 0) {
            coord = vec2(1.0 / 3, 0) + (dir.xz * vec2(-1, 1) + 1);
        } else {
            coord = vec2(0, 0) + (-dir.xz + 1);
        }
    } else {
        if (dir.z > 0) {
            coord = vec2(1.0 / 3, 0.5) + (-dir.xy + 1);
        } else {
            coord = vec2(2.0 / 3, 0) + (dir.xy * vec2(1, -1) + 1);
        }
    }
    return coord;
}


float starVoronoi(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (rand2(gid) - 0.5) * maxDeviation; // Get Point in grid cell
	float d  = sqmag(p-guv);                    // Get distance to that point
    return d;
}
vec2 starVoronoi_getCoord(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (rand2(gid) - 0.5) * maxDeviation; // Get Point in grid cell
    return p;
}

float shootingStar(vec2 coord, vec2 dir, float thickness, float slope) {
	dir    *= 0.9;
	vec2 pa = coord + (dir * 0.5);
    float t = saturate(dot(pa, dir) * ( 1. / dot(dir,dir) ) );
    float d = sqmag(dir * -t + pa);
    return saturate((thickness - d) * slope + 1) * t;
}

vec2 rotation(float angle) {
	return vec2(sin(angle), cos(angle));
}

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

#if defined CUSTOM_SKY
	vec4 skyGradient = getSkyColor_fogArea(viewDir, sunDir, up, sunset, rainStrength, daynight);
#else
	vec4 skyGradient = getSkyColor_fogArea(viewDir, sunDir, up, sunset);
#endif

#ifdef OVERWORLD
#ifdef CUSTOM_STARS

		if (customStarBlend > 1e-6 && playerPos.y > 0) {

			// STARS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = vec3(playerDir.x, skyRot * playerDir.yz);
			skyDir            = vec3(mat2Rot(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = cubemapCoords(skyDir) * 0.35;

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY), 5e3);

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT * (customStarBlend * 3 - 2);
			stars          = saturate(stars + starGlow);
			
			stars         *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);

			float starMask = 1 - skyGradient.a;
			stars         *= starMask;
			
			#ifdef SHOOTING_STARS
			// SHOOTING STARS ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

				vec2 shootingStarCoord = normalize(playerPos * vec3(1,2,1)).xz * shooting_stars_length;

				const vec2 lineDir = vec2(sin(SHOOTING_STARS_ANGLE * TWO_PI), cos(SHOOTING_STARS_ANGLE * TWO_PI));
				shootingStarCoord -= frameTimeCounter * vec2(lineDir * 2 * SHOOTING_STARS_SPEED);
				vec2  gridID       = floor(shootingStarCoord);
				vec2  gridUV       = fract(shootingStarCoord) - 0.5;
				
				float shootingStars = shootingStar(gridUV, lineDir, (9e-8 * shooting_stars_thickness), (5e5 / shooting_stars_thickness));
				shootingStars      *= fstep(shooting_stars_density, rand(gridID));

				float shootingStarMask = saturate(playerDir.y * 2 - 0.3);
				shootingStars         *= shootingStarMask;

				stars = saturate(stars + shootingStars);

			#endif

			// mix: <color> with <starcolor>, depending on <is there a star?> and <is it night?> and <is it blocked by sun or moon?>
			skyGradient.rgb = mix(skyGradient.rgb, vec3(1), stars * customStarBlend * saturate(abs(dot(viewDir, sunDir)) * -200 + 199.5));

		}

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
		float handLightBrightness = smoothstep(handLight.a * 5, 0, dist);
		float handLightBrightnessExp = exp(-dist / handLight.a);
		blockLightColor = blockLightColor + handLight.rgb * handLightBrightness;
		blockLightColor = mix(blockLightColor, handLight.rgb, handLightBrightnessExp);

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

#ifdef FOG

	#ifndef DISTANT_HORIZONS
		float fog = fogFactorTerrain(playerPos);
	#else
		float fog = fogFactorTerrainDH(combinedPlayerPos);
	#endif

	#if defined OVERWORLD && defined CAVE_FOG
		float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(lmcoord.y * 1.5 - 0.25) );
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