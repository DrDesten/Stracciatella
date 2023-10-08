#if ! defined INCLUDE_UTILS_GLSL
#define INCLUDE_UTILS_GLSL


struct blockInfo {
    int id;
    bool emissive;
    int data;
};

blockInfo decodeID( int id ) {
    return blockInfo(
        int(id & 255),
        bool(id & 256),
        int(id >> 9 & 63)
    );
}

int getID( vec4 entityAttribute ) {
    return int(entityAttribute.x) & 255;
}
int getID( int id ) {
    return id & 255;
}
bool getEmissive( vec4 entityAttribute ) {
    return bool(int(entityAttribute.x) & 256);
}
bool getEmissive( int id ) {
    return bool(id & 256);
}
int getData( vec4 entityAttribute ) {
    return int(entityAttribute.x) >> 9;
}
int getData( int id ) {
    return id >> 9;
}

#endif