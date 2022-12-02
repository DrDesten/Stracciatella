vec3 getNormal() {
    return normalize(gl_NormalMatrix * gl_Normal);
}

vec2 getCoord() {
    return mat2(gl_TextureMatrix[0]) * gl_MultiTexCoord0.xy + gl_TextureMatrix[0][3].xy;
}

vec2 getLmCoord() {
    return gl_MultiTexCoord1.xy * (1./240);
}

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
vec3 viewToClip(vec3 viewPos) {
    return mat3(gl_ProjectionMatrix) * viewPos + gl_ProjectionMatrix[3].xyz;
}
vec4 viewToClip(vec4 viewPos) {
    return gl_ProjectionMatrix * viewPos;
}


struct blockInfo {
    int id;
    bool emissive;
    int data;
};
blockInfo decodeID( int id ) {
    return blockInfo(
        int(id & 255),
        bool(id >> 8 & 1),
        int(id >> 9)
    );
}

int getID( vec4 entityAttribute ) {
    return int(entityAttribute.x) & 255;
}
int getID( int id ) {
    return id & 255;
}
bool getEmissive( vec4 entityAttribute ) {
    return bool(int(entityAttribute.x) >> 8 & 1);
}
bool getEmissive( int id ) {
    return bool(id >> 8 & 1);
}
int getData( vec4 entityAttribute ) {
    return int(entityAttribute.x) >> 9;
}
int getData( int id ) {
    return id >> 9;
}