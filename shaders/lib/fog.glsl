
float fogFactor(vec3 viewPos, float far) {
    float farSQ     = sq(far);
    return smoothstep( farSQ * (1.414 * FOG_START / FOG_DISTANCE), farSQ, sqmag(viewPos) * (1.414 / FOG_DISTANCE));
}

float fogFactor(vec3 viewPos, float far, mat4 gbufferModelViewInverse) {
    float farSQ     = sq(far);
    vec3  playerPos = mat3(gbufferModelViewInverse) * viewPos;
    playerPos.y    *= 0.25;
    return smoothstep( farSQ * (1.414 * FOG_START / FOG_DISTANCE), farSQ, sqmag(playerPos) * (1.414 / FOG_DISTANCE));
}


float fogExp(vec3 viewPos, float density) {
    return 1 - exp(-sqmag(viewPos) * density);
}