
// In Geometry Shaders, gl_* vertex attributes are not available
#ifndef GEO

vec3 getNormal() {
    return normalize(gl_NormalMatrix * gl_Normal);
}

#ifdef OPT_UNSAFE
vec2 getCoord() {
    return mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
}
#else
vec2 getCoord() {
    return (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
#endif

#ifdef OPT_SAFE
vec2 getLmCoord() {
    return gl_MultiTexCoord1.xy * (1./240);
}
#else 
vec2 getLmCoord() {
    return (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
#endif

mat3 getTBN(vec4 tangentAttribute) {
	vec3 normal  = normalize(gl_NormalMatrix * gl_Normal);
    vec3 tangent = normalize(gl_NormalMatrix * (tangentAttribute.xyz / tangentAttribute.w));
	return mat3(tangent, cross(tangent, normal), normal);
}


vec3 getView() {
    return mat3(gl_ModelViewMatrix) * gl_Vertex.xyz + gl_ModelViewMatrix[3].xyz;
}
vec4 getView4() {
    return gl_ModelViewMatrix * gl_Vertex;
}

#endif

vec3 viewToClip(vec3 viewPos) {
    return mat3(gl_ProjectionMatrix) * viewPos + gl_ProjectionMatrix[3].xyz;
}
vec4 viewToClip(vec4 viewPos) {
    return gl_ProjectionMatrix * viewPos;
}