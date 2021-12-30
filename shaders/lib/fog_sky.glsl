
// SKY /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 getSkyColor(vec3 viewDir, vec3 sunDir, vec3 up, vec3 skyColor, vec3 fogColor, float sunset) {
    float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

	float fogArea     = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun
	vec3  newFogColor = mix(fogColor, vec3(SKY_SUNSET_R, SKY_SUNSET_G, SKY_SUNSET_B), (sunDot / (1 + sunDot)) * sunset); // Make fog Color change for sunsets

	return mix(skyColor, newFogColor, fogArea);
}





// FOG /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

float fogFactor(vec3 viewPos, float far) {
    float farSQ     = sq(far);
    return smoothstep( farSQ * (1.414 * FOG_START / FOG_END), farSQ, sqmag(viewPos) * (1.414 / FOG_END));
}

float fogFactor(vec3 viewPos, float far, mat4 gbufferModelViewInverse) {
    float farSQ     = sq(far);
    vec3  playerPos = mat3(gbufferModelViewInverse) * viewPos;
    playerPos.y    *= 0.25;
    return smoothstep( farSQ * (1.414 * FOG_START / FOG_END), farSQ, sqmag(playerPos) * (1.414 / FOG_END));
}

float fogExp(vec3 viewPos, float density) {
    return 1 - exp(-length(viewPos) * density);
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



vec3 getFogSkyColor(vec3 viewDir, vec3 sunDir, vec3 up, vec3 skyColor, vec3 fogColor, float sunset, int isEyeInWater) {
    if (isEyeInWater == 0) {
        return getSkyColor(viewDir, sunDir, up, skyColor, fogColor, sunset);
    } else {
        return fogColor;
    }
}