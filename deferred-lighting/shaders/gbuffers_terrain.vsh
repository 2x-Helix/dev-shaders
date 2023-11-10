#version 120

varying vec2 TexCoords;
varying vec3 Normal;
varying vec4 Color;

void main() {
    // Transform the vertex
    gl_Position = ftransform();
    // assign values to varying variables
    TexCoords = gl_MultiTexCoord0.st;
    Normal = gl_NormalMatrix * gl_Normal;  // worldspace norm to viewspace
    Color = gl_Color;
}