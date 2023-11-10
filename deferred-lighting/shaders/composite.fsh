#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;  // Non-normalised direction for sun

uniform sampler2D colortex0;  // Our color texture
uniform sampler2D colortex1;

const float sunPathRotation = -40.0f;
const float Ambient = 0.1f;

void main() {
    // Account for gama correction
    vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2f));
    // get normal
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2.0f - 1.0f);
    // compute cos theta between normal and sun directions
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Lighting calculations
    vec3 Diffuse = Albedo * (NdotL + Ambient);
    /* DRAWBUFFERS:0 */
    // Write diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}