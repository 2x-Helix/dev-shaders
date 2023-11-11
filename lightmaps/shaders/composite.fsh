#version 120

varying vec2 TexCoords;

uniform vec3 sunPosition;  // Non-normalised direction for sun

uniform sampler2D colortex0;  // Our color texture
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;  // Optifine depth texture from eye PoV (also DT1 & DT2)
uniform sampler2D shadowtex0;  // Shadow map

uniform mat4 gbufferProjectionInverse;  // Optrifine provided inverse projection
uniform mat4 gbufferModelViewInverse;  
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

/*
const int colortex0Format = RGBA16F;
const int colortex1Format = RGB16;
const int colortex2Format = RGB16;
*/

const float sunPathRotation = -40.0f;
const float Ambient = 0.025f;
const int shadowMapResolution = 1024;

float AdjustLightmapTorch(in float torch) {
    const float K = 2.0f;
    const float P = 5.06f;
    return K * pow(torch, P);
}

float AdjustLightmapSky(in float sky) {
    float sky_2 = sky * sky;
    return sky_2 * sky_2;
}

vec2 AdjustLightmap(in vec2 Lightmap) {
    vec2 NewLightMap;
    NewLightMap.x = AdjustLightmapTorch(Lightmap.x);  // Lighting from light sources
    NewLightMap.y = AdjustLightmapSky(Lightmap.y);    // Sky lighting
    return NewLightMap;
}

vec3 GetLightmapColor(in vec2 Lightmap) {
    Lightmap = AdjustLightmap(Lightmap);
    // Colours for torch and sky
    const vec3 TorchColor = vec3(1.0f, 0.25f, 0.08f);
    const vec3 SkyColor = vec3(0.05f, 0.15f, 0.3f);
    // Multiply lightmap by colours
    vec3 TorchLighting = Lightmap.x * TorchColor;
    vec3 SkyLighting = Lightmap.y * SkyColor;
    // Sum lighting together to get total lightmap color
    vec3 LightmapLighting = TorchLighting + SkyLighting;
    return LightmapLighting;
}

float GetShadow(float depth) {
    // Returns 1 if not in shadow, 0 if it is
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    return step(SampleCoords.z - 0.001f, texture2D(shadowtex0, SampleCoords.xy).r);
}

void main() {
    // Account for gama correction
    vec3 Albedo = pow(texture2D(colortex0, TexCoords).rgb, vec3(2.2f));
    float Depth = texture2D(depthtex0, TexCoords).r;
    if (Depth == 1.0f) {
        gl_FragData[0] = vec4(Albedo, 1.0f);
        return;
    }
    // get normal
    vec3 Normal = normalize(texture2D(colortex1, TexCoords).rgb * 2.0f - 1.0f);
    // get lightmap
    vec2 Lightmap = texture2D(colortex2, TexCoords).rg;  // Blue channel will be used as a mask map
    // Lightmap color
    vec3 LightmapColor = GetLightmapColor(Lightmap);
    // compute cos theta between normal and sun directions
    float NdotL = max(dot(Normal, normalize(sunPosition)), 0.0f);
    // Lighting calculations
    vec3 Diffuse = Albedo  * (LightmapColor + NdotL + GetShadow(Depth) + Ambient);
    // vec3 Diffuse = (Albedo + LightmapColor)  * (NdotL + Ambient);
    /* DRAWBUFFERS:0 */
    // Write diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}