#version 120

varying vec2 TexCoords;

// Converts albedo from sRGB to linear sRGB
void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;
}