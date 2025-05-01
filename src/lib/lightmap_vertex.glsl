uniform vec3 up;

float getTerrainShading(vec3 glNormal, int blockId) {
    bool isExempt = blockId == 10 || blockId == 11 || blockId == 17 || blockId == 12;
    if (isExempt) return 1;
    return dot(normalize(vec3(.25, 1, .5)), glNormal) * 0.15 + 0.85;
}

float getEntityShading(vec3 viewNormal) {
    return dot(up, viewNormal) * 0.35 + 0.65;
}