uniform sampler2D gcolor;  // Color
uniform sampler2D lightmap; // lightmap

vec4 getAlbedo(vec2 coord) {
    return texture(gcolor, coord);
}

vec3 getLightmap(vec2 lmcoord) {
    return texture(lightmap, lmcoord).rgb;
}

uint encodeLMCoordBuffer(vec4 data) {
    uvec4 idata = uvec4(saturate(data) * 255 + 0.5);
    
    uint encoded = idata.x;
    encoded     += idata.y << 8;
    encoded     += idata.z << 16;
    encoded     += idata.w << 24;
    return encoded;
}
vec4 decodeLMCoordBuffer(uint encoded) {
    return vec4(
		float(encoded & 255) * (1./255),
		float((encoded >> 8) & 255) * (1./255),
		float((encoded >> 16) & 255) * (1./255),
		float(encoded >> 24) * (1./255)
	);
}