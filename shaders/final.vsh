#version 120

varying vec2 TexCoords;  // Texture coord into fragment shader

void main() {
    gl_Position = ftransform();
    TexCoords = gl_MultiTexCoord0.st;  // Built-in texrture coord attribute
}