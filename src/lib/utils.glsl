
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

int getID( int id ) {
    return id & 255;
}
int getID( vec4 entityAttribute ) {
    return getID(int(entityAttribute.x));
}
bool getEmissive( int id ) {
    return bool(id & 256);
}
bool getEmissive( vec4 entityAttribute ) {
    return getEmissive(int(entityAttribute.x));
}
int getData( int id ) {
    return id >> 9;
}
int getData( vec4 entityAttribute ) {
    return getData(int(entityAttribute.x));
}