
/* float fogFactor(vec3 viewPos, float farInverse) {
    return exp(min(0, -sqmag(viewPos) * sq(farInverse * FOG_DISTANCE) + FOG_START));
} */

float fogFactor(vec3 viewPos, float far) {
    return smoothstep(0, sq(far), sqmag(viewPos) * (1. / FOG_DISTANCE));
}