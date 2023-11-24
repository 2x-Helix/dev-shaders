#version 120

varying vec2 TexCoords;
varying vec2 LightmapCoords;
varying vec3 Normal;
varying vec4 Color;

void main() {
    // Transform the vertex
    gl_Position = ftransform();
    // assign values to varying variables
    TexCoords = gl_MultiTexCoord0.st;
    // Multiply luight by texture matrix to move range from [0, 15] -> [0, 1]
    LightmapCoords = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    // Transform into range
    LightmapCoords = (LightmapCoords * 33.05f / 32.0f) - (1.05f / 32.0f);
    Normal = gl_NormalMatrix * gl_Normal;  // worldspace norm to viewspace
    Color = gl_Color;
}