float getImportance(vec3 rgb) {
    return maxc(rgb);
}

vec3 encodeImportance(vec3 lab, float importance) {
    lab.yz /= max(lab.x, 1);
    lab.x   = importance;
    return lab;
}
float decodeImportance(vec3 lab) {
    return lab.x;
}
vec3 decodeColor(vec3 lab) {
    lab.x = 0.5;
    return lab;
}