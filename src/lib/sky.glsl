#include "/core/dh/uniforms.glsl"

const vec3 sunsetColor = vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B);

const vec3 skyDayColor       = vec3(SKY_DAY_R, SKY_DAY_G, SKY_DAY_B);
const vec3 skyDayRainColor   = vec3(SKY_DAY_RAIN_R, SKY_DAY_RAIN_G, SKY_DAY_RAIN_B);
const vec3 skyNightColor     = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B) * SKY_NIGHT_BRIGHTNESS;
const vec3 skyNightRainColor = vec3(SKY_NIGHT_RAIN_R, SKY_NIGHT_RAIN_G, SKY_NIGHT_RAIN_B) * SKY_NIGHT_BRIGHTNESS;

const vec3 fogCaveColor = vec3(FOG_CAVE_R, FOG_CAVE_G, FOG_CAVE_B);

const vec3 fogDayColor       = vec3(FOG_DAY_R, FOG_DAY_G, FOG_DAY_B);
const vec3 fogDayRainColor   = vec3(FOG_DAY_RAIN_R, FOG_DAY_RAIN_G, FOG_DAY_RAIN_B);
const vec3 fogNightColor     = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B) * FOG_NIGHT_BRIGHTNESS;
const vec3 fogNightRainColor = vec3(FOG_NIGHT_RAIN_R, FOG_NIGHT_RAIN_G, FOG_NIGHT_RAIN_B) * FOG_NIGHT_BRIGHTNESS;

const vec3 endSkyUp   = vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B);
const vec3 endSkyDown = vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B);

uniform float sunset;
uniform float daynight;
uniform float rainStrength;
uniform int   isEyeInWater;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform float far;
uniform vec3  up;

// SKY /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

#ifdef CUSTOM_SKY

vec4 getSkyColor_fogArea(vec3 viewDir, vec3 sunDir) {
    #ifdef NETHER

        return vec4(fogColor, 1);

    #endif
    #ifdef END 
    
        float viewHeight = dot(viewDir, up) * 0.5 + 0.5;
        return vec4(mix(vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B), vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B), viewHeight), 1);

    #endif
    
    float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

	float fogArea = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun

    #ifdef SKY_CUSTOM_COLOR
        // Custom Sky Color
	    vec3 skyRainColor  = mix(vec3(SKY_NIGHT_RAIN_R, SKY_NIGHT_RAIN_G, SKY_NIGHT_RAIN_B), vec3(SKY_DAY_RAIN_R, SKY_DAY_RAIN_G, SKY_DAY_RAIN_B), daynight);
	    vec3 skyClearColor = mix(vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B),                vec3(SKY_DAY_R, SKY_DAY_G, SKY_DAY_B), daynight);
        vec3 skyCol        = mix(skyClearColor, skyRainColor, rainStrength);
    #else
        vec3 skyCol = skyColor;
    #endif
    #ifdef FOG_CUSTOM_COLOR
        // Custom Fog Color
	    vec3 fogRainColor  = mix(vec3(FOG_NIGHT_RAIN_R, FOG_NIGHT_RAIN_G, FOG_NIGHT_RAIN_B), vec3(FOG_DAY_RAIN_R, FOG_DAY_RAIN_G, FOG_DAY_RAIN_B), daynight); 
	    vec3 fogClearColor = mix(vec3(FOG_NIGHT_R, FOG_NIGHT_G, FOG_NIGHT_B),                vec3(FOG_DAY_R, FOG_DAY_G, FOG_DAY_B), daynight);
        vec3 fogCol        = mix(fogClearColor, fogRainColor, rainStrength);
    #else
        vec3 fogCol = fogColor;
    #endif

    #ifdef SKY_CUSTOM_SUNSET
	    fogCol = mix(fogCol, vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B), (sunDot * 10 / (0.45 + sunDot * 9)) * sunset); // Make fog Color change for sunsets
    #endif


    //return vec4(vec3(sunset), fogArea);
	return vec4(mix(skyCol, fogCol, fogArea), fogArea);
}

#else

vec4 getSkyColor_fogArea(vec3 viewDir, vec3 sunDir) {
    #ifdef NETHER

        return vec4(fogColor, 1);

    #endif
    #ifdef END 
    
        float viewHeight = dot(viewDir, up) * 0.5 + 0.5;
        return vec4(mix(vec3(END_SKY_DOWN_R, END_SKY_DOWN_G, END_SKY_DOWN_B), vec3(END_SKY_UP_R, END_SKY_UP_G, END_SKY_UP_B), viewHeight), 1);

    #endif

    float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

    vec3  fogCol  = fogColor;
	float fogArea = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun
    
    #ifdef SKY_CUSTOM_SUNSET
	    fogCol = mix(fogCol, vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B), (sunDot / (1 + sunDot)) * sunset); // Make fog Color change for sunsets
    #endif

	return vec4(mix(skyColor, fogCol, fogArea), fogArea);
}

#endif

vec3 getSkyColor(vec3 viewDir, vec3 sunDir) { return getSkyColor_fogArea(viewDir, sunDir).rgb; }

vec3 getCustomFogColor() {
    vec3 fogRainColor  = mix(vec3(FOG_NIGHT_RAIN_R, FOG_NIGHT_RAIN_G, FOG_NIGHT_RAIN_B), vec3(FOG_DAY_RAIN_R, FOG_DAY_RAIN_G, FOG_DAY_RAIN_B), daynight); 
    vec3 fogClearColor = mix(vec3(FOG_NIGHT_R, FOG_NIGHT_G, FOG_NIGHT_B),                vec3(FOG_DAY_R, FOG_DAY_G, FOG_DAY_B), daynight);
    return mix(fogClearColor, fogRainColor, rainStrength);
}



// FOG /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float fogSmoothStep(float distSq, float far) {
    float farSQ = sq(far);
    return smoothstep( farSQ * (SQRT2 * FOG_START / FOG_END), farSQ, distSq * (SQRT2 / FOG_END));
}

#ifdef DISTANT_HORIZONS
float fogFactorTerrain(vec3 playerPos) {
    return fogSmoothStep(sqmag(playerPos.xz), dhFarPlane);
}
#else
float fogFactorTerrain(vec3 playerPos) {
    playerPos.y *= 0.25;
    return fogSmoothStep(sqmag(playerPos), far);
}
#endif


float fogExp(vec3 viewPos, float density) {
    return 1 - exp(-length(viewPos) * density);
}
float fogExp(float dist, float density) {
    return 1 - exp(-dist * density);
}

float fogBorderExp( float dist, float far, float density ) {
    float farFog = exp( -far * SQRT2 * density );
    float expFog = exp( -dist * density );
    return 1 - saturate( expFog - farFog ) * (1 + farFog); // Dividing by (1 - farFog) is technically correct here, but for small farFog they are close. Multiplication is faster.
}

float expFogDensity(float worldHeight) {
    worldHeight = exp(-(worldHeight - FOG_EXP_START) * ( 1. / (FOG_EXP_END - FOG_EXP_START)) );
    return (worldHeight);
}
float expFogDensityIntegral(float worldHeight) {
    worldHeight = exp((worldHeight - FOG_EXP_START) * ( -1. / (FOG_EXP_END - FOG_EXP_START)) ) * (FOG_EXP_END - FOG_EXP_START);
    return (worldHeight);
}
float expHeightFog(float dist, float cameraY, float pixelY) {
    float fogDensity = (expFogDensityIntegral(pixelY) - expFogDensityIntegral(cameraY)) / (cameraY - pixelY);
    fogDensity       = fogDensity * dist * FOG_EXP_DENSITY;
    return 1 - exp(-fogDensity);
}

vec3 getFogSkyColor(vec3 viewDir, vec3 sunDir) {
    if (isEyeInWater == 0) {
        return getSkyColor(viewDir, sunDir);
    } else {
        return fogColor;
    }
}

	
#ifdef FOG_EXPERIMENTAL

#include "/core/transform.glsl"

// FOG_EXPERIMENTAL density based on y-value
float FE_density(float y, float df) {
	return 1 - exp(-df * y);
}
// Integral of FE_density
float FE_densityI(float y, float df) {
	return (1 / df) * exp(-df * y) + y;
}

float fogFactorExperimental(vec3 playerPos)	{
    vec3 worldPos = toWorld(playerPos);

#if 0

    vec3 playerNormY = playerPos / abs(playerPos.y);
    const float fe_start_height = 100;
    const float fe_start = 0;
    const float fe_end_height = 80;
    const float fe_end = 0.01;
    const float fe_height = fe_start_height - fe_end_height;

    float fe_density = 0;

    if ( cameraPosition.y >= fe_start_height && worldPos.y < fe_start_height ) {
        float hit_mix     = saturate((worldPos.y - fe_end_height) / fe_height);
        float hit_density = mix(fe_end, fe_start, hit_mix);

        vec3 hit_ray = playerPos 
            - (playerNormY * max(0, cameraPosition.y - fe_start_height)) // Remove part of ray before medium
            - (playerNormY * max(0, fe_end_height - worldPos.y));        // Remove part of ray after medium
        
        fe_density += hit_density * length(hit_ray);

        //color = vec3(length(hit_ray)) / 100;
    }

    float fe = exp2(-fe_density);
    return fe;

#else 

    const float morningShift  = 20;
    const float morningScale  = 0.02;
    const float morningFactor = 0.008;

    const float noonShift  = 20;
    const float noonScale  = 0.03;
    const float noonFactor = 0.004;
    
    const float rainShift  = 40;
    const float rainScale  = 0.027;
    const float rainFactor = 0.07;

    #if 1
    float shift  = mix( mix(noonShift,  morningShift, sunset), rainShift, rainStrength );
    float scale  = mix( mix(noonScale,  morningScale, sunset), rainScale, rainStrength );
    float factor = mix( mix(noonFactor, morningFactor, sunset), rainFactor, rainStrength );
    #else
    const float shift = 40;
    const float scale = 0.027;
    const float factor = 0.08;
    #endif

    const float dfacMin = 80;
    const float dfacMax = 200;
    float dynamicFactor = 0.5 + smoothstep(dfacMin, dfacMax, cameraPosition.y);

    float diff = (
        FE_densityI(worldPos.y - shift, scale) - 
        FE_densityI(cameraPosition.y - shift, scale)
    ) / (worldPos.y - cameraPosition.y);

    float density = saturate(1 - diff) * factor * dynamicFactor;
    float fe = exp2(-length(playerPos) * density);

    return fe;
    
#endif
}

#endif