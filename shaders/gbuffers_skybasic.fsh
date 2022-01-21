

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/fog_sky.glsl"

uniform vec2 screenSizeInverse;
uniform vec3 fogColor;
uniform vec3 skyColor;

uniform vec3  sunDir;
uniform vec3  up;
uniform float sunset;
#ifdef CUSTOM_SKY
uniform float daynight;
uniform float rainStrength;
#endif

varying vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.
varying vec3 viewPos;

#ifdef CUSTOM_STARS
varying vec3  playerPos;
uniform float normalizedTime;
uniform float customStarBlend;
#endif

#ifdef SHOOTING_STARS
uniform float frameTimeCounter;
#endif

vec2 signNotZero(vec2 v) {
    return vec2((v.x >= 0.0) ? +1.0 : -1.0, (v.y >= 0.0) ? +1.0 : -1.0);
}
vec2 octahedralEncode(vec3 v) {
    float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
    vec2  result = v.xy * (1.0 / l1norm);
    if (v.z < 0.0) {
        result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
    }
    return result;
}
vec3 octahedralDecode(vec2 o) {
    vec3 v = vec3(o.x, o.y, 1.0 - abs(o.x) - abs(o.y));
    if (v.z < 0.0) {
        v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
    }
    return normalize(v);
}



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
	vec2 p   = (N22(gid) - 0.5) * maxDeviation; // Get Point in grid cell
	float d  = sqmag(p-guv);                    // Get distance to that point
    return d;
}
vec2 starVoronoi_getCoord(vec2 coord, float maxDeviation) {
    vec2 guv = fract(coord) - 0.5;
    vec2 gid = floor(coord);
	vec2 p   = (N22(gid) - 0.5) * maxDeviation; // Get Point in grid cell
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

/* DRAWBUFFERS:0 */
void main() {
	vec3 viewDir = normalize(viewPos);
	#ifdef CUSTOM_SKY
	vec4 sky = getSkyColor_fogArea(viewDir, sunDir, up, skyColor, fogColor, sunset, rainStrength, daynight);
	#else
	vec4 sky = getSkyColor_fogArea(viewDir, sunDir, up, skyColor, fogColor, sunset);
	#endif

	#ifdef CUSTOM_STARS

		vec3 color = sky.rgb;

		if (starData.a < 0.5 && customStarBlend > 1e-6 && playerPos.y > 0) {

			vec3 playerDir = normalize(playerPos);

			// STARS /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			const mat2 skyRot = mat2(cos(sunPathRotation * (PI/180.)), sin(sunPathRotation * (PI/180.)), -sin(sunPathRotation * (PI/180.)), cos(sunPathRotation * (PI/180.)));
			vec3 skyDir       = vec3(playerDir.x, skyRot * playerDir.yz);
			skyDir            = vec3(rotationMatrix2D(normalizedTime * -TWO_PI) * skyDir.xy, skyDir.z);
			vec2 skyCoord     = cubemapCoords(skyDir) * 0.35;

			float starNoise = starVoronoi(skyCoord * STAR_DENSITY, 0.85);
			float stars     = fstep(starNoise, (STAR_SIZE * 1e-4 * STAR_DENSITY));

			float starGlow = exp(-starNoise * star_glow_size) * STAR_GLOW_AMOUNT * (customStarBlend * 3 - 2);
			stars          = saturate(stars + starGlow);
			
			stars         *= fstep(noise(skyCoord * 10), STAR_COVERAGE, 2);

			float starMask = 1 - sky.a;
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
			color = mix(color, vec3(1), stars * customStarBlend * saturate(abs(dot(viewDir, sunDir)) * -200 + 199.5));

			//color = vec3(saturate(abs(dot(viewDir, sunDir)) * -200 + 199.5));

		} else if (starData.a >= 0.5) {

			color = vec3(0);

		}

	#else

		float starMask = 1 - sky.a;
		vec3  color = mix(sky.rgb, saturate(starData.rgb * STAR_BRIGHTNESS) * starMask, starData.a);

	#endif

	//color = vec3(pow( cos( normalizedTime * PI * 4 ) * 0.5 + 0.5, 1 ));

	#if DITHERING >= 1
		color += ditherColor(gl_FragCoord.xy);
	#endif
	gl_FragData[0] = vec4(color, 1.0); //gcolor
}