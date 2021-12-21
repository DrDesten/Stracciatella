
/* float fogFactor(vec3 viewPos, float farInverse) {
    return exp(min(0, -sqmag(viewPos) * sq(farInverse * FOG_DISTANCE) + FOG_START));
} */

float fogFactor(vec3 viewPos, float far) {
    float farSQ = sq(far);
    return smoothstep(farSQ * (1.414 * FOG_START / FOG_DISTANCE), farSQ, sqmag(viewPos) * (1.414 / FOG_DISTANCE));
}