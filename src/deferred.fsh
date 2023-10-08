#include "/lib/settings.glsl"
#include "/core/math.glsl"
#include "/lib/utils.glsl"
#include "/core/kernels.glsl"
#include "/lib/composite_basics.glsl"
#include "/lib/transform.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex1;

#ifdef FOG

 uniform int   isEyeInWater;
 uniform float far;

 #ifdef OVERWORLD
  uniform ivec2 eyeBrightnessSmooth;
 #endif

#endif

uniform vec3  sunDir;
uniform vec3  up;
uniform vec3  upPosition;
uniform float sunset;
#ifdef CUSTOM_SKY
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
uniform sampler2D colortex4; 
#if LIGHTMAP_COLOR_DEBUG != 0
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


vec4 getLightmap(vec2 coord) {
    return vec2x16to4(texture(colortex1, coord).xy);
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

	#ifdef CUSTOM_SKY
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

	if (depth >= 1) { 

		#ifdef OVERWORLD
		color += skyGradient.rgb;
		#ifdef CAVE_SKY
		float cave = max( saturate(eyeBrightnessSmooth.y * (4./240.) - 0.25), saturate(cameraPosition.y * 0.25 - (CAVE_SKY_HEIGHT * 0.25)) );
		color = mix(fogCaveColor, color, cave);
		#endif
		#else
		color = skyGradient.rgb;
		#endif

	} else {

		vec4 lmcoord = getLightmap(coord);

		#ifdef COLORED_LIGHTS

			vec3 blockLightColor = (textureBicubic(colortex4, coord, vec2(16,9), 1./vec2(16,9)).rgb);
			blockLightColor = blockLightColor / (maxc(blockLightColor) + 0.02);
			blockLightColor = saturate(applyVibrance(blockLightColor, LIGHTMAP_COLOR_VIBRANCE));

			float dist = sqmag(playerPos);
			float handLightBrightness = smoothstep(handLight.a * 5, 0, dist);
			float handLightBrightnessExp = exp(-dist / handLight.a);
			blockLightColor = blockLightColor + handLight.rgb * handLightBrightness;
			blockLightColor = mix(blockLightColor, handLight.rgb, handLightBrightnessExp);

			#if LIGHTMAP_COLOR_DEBUG == 0 // No Debug, Normal Mode

			color *= getCustomLightmap(lmcoord.xyz, customLightmapBlend, blockLightColor) * (1 - lmcoord.a) + lmcoord.a;

			#elif LIGHTMAP_COLOR_DEBUG == 1 // Debug, Mix Mode

			color = mix(color, blockLightColor * (1 - lmcoord.a) + lmcoord.a, 0.666);
			vec3 tmp = texture(colortex5, coord).rgb;
			if (sum(tmp) != 0) color = tmp;

			#elif LIGHTMAP_COLOR_DEBUG == 2 // Debug, Pure Mode

			color = blockLightColor * (1 - lmcoord.a) + lmcoord.a;

			#elif LIGHTMAP_COLOR_DEBUG == 3 // Debug, Source Mode

			vec3 tmp = texture(colortex5, coord).rgb;
			if (sum(tmp) != 0) color = tmp;
			else color = mix(color, vec3(1,0,0), 0.5);
			
			#endif

		#else

			color *= getCustomLightmap(lmcoord.xyz, customLightmapBlend) * (1 - lmcoord.a) + lmcoord.a;

		#endif

		//color.rg = lmcoord.xy;
		//color = lmcoord.xyz;
		//color = texture(colortex4, coord).rgb;
		//color *= mix(blockLightColor, color, lmcoord.a);

		#ifdef FOG
			float fog = fogFactorPlayer(playerPos, far);
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