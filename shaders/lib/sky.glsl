
vec3 getSkyColor(vec3 viewDir, vec3 sunDir, vec3 up, vec3 skyColor, vec3 fogColor, float sunset) {
    float sunDot  = sq(dot(viewDir, sunDir) * 0.5 + 0.5);
	#ifdef SUN_SIZE_CHANGE
		sunDot = sunDot * (SUN_SIZE * 0.25) + sunDot;
	#endif

	float fogArea = smoothstep(-sunDot * 0.5 - 0.1, 0.05, dot(viewDir, -up)); // Adding sunDot to the upper smoothstep limit to increase fog close to sun
	vec3  newFogColor = mix(fogColor, vec3(1,0.4,0), (sunDot / (1 + sunDot)) * sunset); // Make fog Color change for sunsets

	return mix(skyColor, newFogColor, fogArea);
}