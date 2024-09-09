uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

// In Geometry Shaders, gl_* vertex attributes are not available
#ifndef GEO

#ifdef SMOOTHCAM
uniform vec3 cameraPositionSmooth;

vec4 smoothPlayer(vec4 vertex) {
    return vec4((gbufferModelViewInverse * (gl_ModelViewMatrix * vertex)).xyz + cameraPosition - cameraPositionSmooth, 1);
}
vec4 smoothPlayer() {
    return smoothPlayer(gl_Vertex);
}
vec3 smoothWorld(vec4 vertex) {
    return smoothPlayer(vertex).xyz + cameraPosition;
}
vec3 smoothWorld() {
    return smoothWorld(gl_Vertex);
}
vec4 smoothView(vec4 vertex) {
    return gbufferModelView * smoothPlayer(vertex);
}
vec4 smoothView() {
    return smoothView(gl_Vertex);
}
vec4 smoothClip(vec4 vertex) {
    return gl_ProjectionMatrix * smoothView(vertex);
}
vec4 smoothClip() {
    return smoothClip(gl_Vertex);
}


vec4 getPosition(vec4 vertex) {
    return smoothClip(vertex);
}
vec4 getPosition() {
    return smoothClip();
}
#else 
vec4 getPosition(vec4 vertex) {
    return gl_ModelViewProjectionMatrix * vertex;
}
vec4 getPosition() {
    return getPosition(gl_Vertex);
}
#endif

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

#ifdef SMOOTHCAM
vec3 getView(vec4 vertex) { return smoothView(vertex).xyz; }
vec4 getView4(vec4 vertex) { return smoothView(vertex); }
vec3 getView() { return smoothView().xyz; }
vec4 getView4() { return smoothView(); }
#else
vec3 getView(vec4 vertex) {
    return mat3(gl_ModelViewMatrix) * vertex.xyz + gl_ModelViewMatrix[3].xyz;
}
vec3 getView() {
    return getView(gl_Vertex);
}
vec4 getView4(vec4 vertex) {
    return gl_ModelViewMatrix * vertex;
}
vec4 getView4() {
    return getView4(gl_Vertex);
}
#endif

#endif

vec3 viewToClip(vec3 viewPos) {
    return mat3(gl_ProjectionMatrix) * viewPos + gl_ProjectionMatrix[3].xyz;
}
vec4 viewToClip(vec4 viewPos) {
    return gl_ProjectionMatrix * viewPos;
}