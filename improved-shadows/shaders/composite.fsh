#version 120
#include "distort.glsl"

varying vec2 TexCoords;

uniform vec3 sunPosition;  // Non-normalised direction for sun

uniform sampler2D colortex0;  // Our color texture
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;  // Optifine depth texture from eye PoV (also DT1 & DT2)
uniform sampler2D shadowtex0;  // Shadow map
uniform sampler2D shadowtex1;  // Like shadowtex0 without any transparent objects
uniform sampler2D shadowcolor0;  // Shadow color
uniform sampler2D noisetex;

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
const int shadowMapResolution = 1024;
const int noiseTextureResolution = 128; 
const float Ambient = 0.025f;

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

float Visibility(in sampler2D ShadowMap, in vec3 SampleCoords) {
    // Returns if a fragment is visible at SampleCoords using the shadow map
    return step(SampleCoords.z - 0.001f, texture2D(ShadowMap, SampleCoords.xy).r);
}

vec3 TransparentShadow(in vec3 SampleCoords) {
    float ShadowVisibility0 = Visibility(shadowtex0, SampleCoords);  // Sample shadow depth textures
    float ShadowVisibility1 = Visibility(shadowtex1, SampleCoords);
    vec4 ShadowColor0 = texture2D(shadowcolor0, SampleCoords.xy);
    vec3 TransmittedColor = ShadowColor0.rgb * (1.0f - ShadowColor0.a);  // Blend operation
    return mix(TransmittedColor * ShadowVisibility1, vec3(1.0f), ShadowVisibility0);  // Return transmitted colour if no opaque object
}

#define SHADOW_SAMPLES 2
const int ShadowSamplesPerSize = 2 * SHADOW_SAMPLES + 1;
const int TotalSamples = ShadowSamplesPerSize * ShadowSamplesPerSize;

vec3 GetShadow(float depth) {
    // Returns 1 if not in shadow, 0 if it is
    vec3 ClipSpace = vec3(TexCoords, depth) * 2.0f - 1.0f;
    vec4 ViewW = gbufferProjectionInverse * vec4(ClipSpace, 1.0f);
    vec3 View = ViewW.xyz / ViewW.w;
    vec4 World = gbufferModelViewInverse * vec4(View, 1.0f);
    vec4 ShadowSpace = shadowProjection * shadowModelView * World;
    ShadowSpace.xy = DistortPosition(ShadowSpace.xy);
    vec3 SampleCoords = ShadowSpace.xyz * 0.5f + 0.5f;
    
    vec3 ShadowAccum = vec3(0.0f);
    float RandomAngle = texture2D(noisetex, TexCoords * 20.0f).r * 100.0f;
    float cosTheta = cos(RandomAngle);
    float sinTheta = sin(RandomAngle);
    mat2 Rotation = mat2(cosTheta, -sinTheta, sinTheta, cosTheta) / shadowMapResolution;  // We can move our division by the shadow map resolution here for a small speedup
    for (int x = -SHADOW_SAMPLES; x <= SHADOW_SAMPLES; x++) {
        for (int y = -SHADOW_SAMPLES; y <= SHADOW_SAMPLES; y++) {
            vec2 Offset = Rotation * vec2(x, y); 
            vec3 CurrentSampleCoordinate = vec3(SampleCoords.xy + Offset, SampleCoords.z);
            ShadowAccum += TransparentShadow(CurrentSampleCoordinate);
        }
    }
    ShadowAccum /= TotalSamples;
    return ShadowAccum;
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
    /* DRAWBUFFERS:0 */
    // Write diffuse color
    gl_FragData[0] = vec4(Diffuse, 1.0f);
}