/* The original author might be hunterk ? */

#pragma parameter SCANTHICK "Scanline Thickness" 2.0 2.0 4.0 2.0
#pragma parameter INTENSITY "Scanline Intensity" 0.15 0.0 1.0 0.01
#pragma parameter BRIGHTBOOST "Luminance Boost" 0.15 0.0 1.0 0.01

#ifdef PARAMETER_UNIFORM
uniform float SCANTHICK;
uniform float INTENSITY;
uniform float BRIGHTBOOST;

#else
#define SCANTHICK 2.0
#define INTENSITY 0.15
#define BRIGHTBOOST 0.15

#endif

#if defined(VERTEX)
void main(
  float2 TexCoord,
  float2 VertexCoord,
  float4 Color,

  uniform float4x4 MVPMatrix,

  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,
  float4 out oColor    : COLOR
) {
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
  oTexCoord = TexCoord;
  oColor = Color;
}

#elif defined(FRAGMENT)

float4 crt_nes_mini(
  float2 TextureSize, 
  float2 TexCoord, 
  sampler2D vTexture
) {
    float3 texel = tex2D(vTexture, TexCoord).rgb;

    float3 pixelHigh = ((1.0 + BRIGHTBOOST) - (0.2 * texel)) * texel;
    float3 pixelLow  = ((1.0 - INTENSITY) + (0.1 * texel)) * texel;

    float selectY = fmod(TexCoord.y * SCANTHICK * TextureSize.y, 2.0);
    float selectHigh = step(1.0, selectY);
    float selectLow = 1.0 - selectHigh;
    
    float3 pixelColor = (selectLow * pixelLow) + (selectHigh * pixelHigh);

    return float4(pixelColor, 1.0);
}

void main(
  float2 TexCoord : TEXCOORD0,

  uniform float2 TextureSize,
  uniform sampler2D vTexture,

  float4 out oColor : COLOR
) {
	oColor = crt_nes_mini(TextureSize, TexCoord, vTexture);
}

#endif