/* The original author might be hunterk ? */

#pragma parameter SCANTHICK "Scanline Thickness" 2.0 2.0 4.0 2.0
#pragma parameter INTENSITY "Scanline Intensity" 0.15 0.0 1.0 0.01
#pragma parameter BRIGHTBOOST "Luminance Boost" 0.15 0.0 1.0 0.01
#pragma parameter CURVATURE_X "Screen curvature - horizontal" 0.10 0.0 1.0 0.01
#pragma parameter CURVATURE_Y "Screen curvature - vertical" 0.15 0.0 1.0 0.01

#ifdef PARAMETER_UNIFORM
uniform float SCANTHICK;
uniform float INTENSITY;
uniform float BRIGHTBOOST;
uniform float CURVATURE_X;
uniform float CURVATURE_Y;

#else
#define SCANTHICK 2.0
#define INTENSITY 0.15
#define BRIGHTBOOST 0.15
#define CURVATURE_X 0.10
#define CURVATURE_Y 0.25

#endif

#define MAX pow(0.2, 4)
#define ASPECT float2(1.0, 0.75)

float2 distort(float2 coord, float2 screenScale) {
  float2 uv = coord;

  float2 CURVATURE_DISTORTION = float2(CURVATURE_X, CURVATURE_Y);

  // Barrel distortion shrinks the display area a bit,
  // this will allow us to counteract that.
  float2 barrelScale = 1.0 - (0.23 * CURVATURE_DISTORTION);

  uv *= screenScale;
  uv -= float2(0.5);

  float rsq = uv.x * uv.x + uv.y * uv.y;

  uv += uv * (CURVATURE_DISTORTION * rsq);
  uv *= barrelScale;

  if (abs(uv.x) >= 0.5 || abs(uv.y) >= 0.5) {
    uv = float2(-1.0);   // If out of bounds, return an invalid value.

  } else {
    uv += float2(0.5);
    uv /= screenScale;
  }

  return uv;
}

#if defined(VERTEX)

void main(
  float2 TexCoord,
  float2 VertexCoord,
  float4 Color,

  uniform float4x4 MVPMatrix,
  uniform float2 TextureSize,
  uniform float2 InputSize,
  uniform float2 OutputSize,

  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,
  float4 out oColor    : COLOR,
  float4 out screenScaleFilterWidth : TEXCOORD1
) {
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
  oTexCoord = TexCoord;
  oColor = Color;

  screenScaleFilterWidth.xy = TextureSize / InputSize;
  screenScaleFilterWidth.zw = (InputSize.y / OutputSize.y) / 3.0;
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

/* Almost vignette mask. This float can be multitplied by a color to determine its final product */
float corner(
  float2 uv,
  float2 screenScale
) {
  float2 coord = uv;

  coord *= screenScale;
  coord = min(coord, float2(1.0) - coord) * ASPECT;

  float2 cdist = float2(0.03);
  coord = (cdist - min(coord,cdist));

  float dist = sqrt(dot(coord,coord));

  return clamp((cdist.x - dist) * 1000.0, 0.0, 1.0);
}

void main(
  float2 TexCoord : TEXCOORD0,
  float4 screenScaleFilterWidth  : TEXCOORD1,

  uniform float2 TextureSize,
  uniform float2 OutputSize,
  uniform float2 InputSize,
  uniform sampler2D vTexture,

  float4 out oColor : COLOR
) {

  float2 uv = distort(TexCoord, screenScaleFilterWidth.xy);

  float4 color = crt_nes_mini(TextureSize, uv, vTexture);

  float mask = corner(uv, screenScaleFilterWidth.xy);

  color.rgb = color.rgb * float3(mask);
  oColor = color;
}

#endif