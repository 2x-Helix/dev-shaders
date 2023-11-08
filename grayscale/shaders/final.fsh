#version 120

varying vec2 TexCoords;  // Input texture coordinate from vertex shader
uniform sampler2D colortex0;  // Input texture from standard optifine pipeline

void main() {
    // sample color
    vec3 Color = texture2D(colortex0, TexCoords).rgb;  // sample colortex0
    // Convert to grayscale
    Color = vec3(dot(Color, vec3(0.333f)));  // Convert to grayscale by multiplying each channel by 0.333f
    // Output color
    gl_FragColor = vec4(Color, 1.0f);  // Output result to the pipeline
}