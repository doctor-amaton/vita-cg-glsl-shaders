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

#define d 1.5
#define R 2.0

#define MAX pow(0.2, 4)
#define FIX(c) max(abs(c), 1e-5)
#define ASPECT float2(1.0, 0.75)

float intersect(float2 xy, float4 sin_cos_angle)
{
  float A = dot(xy, xy) + d * d;
  float B = 2.0 * (
    R * (dot(xy, sin_cos_angle.xy) - d * sin_cos_angle.zw.x * sin_cos_angle.zw.y) - d * d
  );

  float C = d * d + 2.0 * R * d * sin_cos_angle.zw.x * sin_cos_angle.zw.y;
  return (-B - sqrt(B * B - 4.0 * A * C)) / (2.0 * A);
}

float2 fwtrans(float2 coord) {
  float4 sin_cos_angle = (0.0, 0.0, 1.0, 1.0);

  float2 uv = coord;
  float r = FIX(sqrt(dot(uv,uv)));

  uv *= sin(r/R)/r;

  float x = 1.0-cos(r/R);
  float D = d/R + x * sin_cos_angle.z * sin_cos_angle.w + dot(uv, sin_cos_angle.xy);

  return d * (uv * sin_cos_angle.zw - x * sin_cos_angle.xy) / D;
}

float2 bkwtrans(float2 xy) {
  float4 sin_cos_angle = (0.0, 0.0, 1.0, 1.0);

  float c = intersect(xy, sin_cos_angle);
  float2 point_ = float2(c,c) * xy;

  point_ -= float2(-R, -R) * sin_cos_angle.xy;
  point_ /= float2(R, R);

  float2 tang = sin_cos_angle.xy / sin_cos_angle.zw;
  float2 poc = point_ / sin_cos_angle.zw;

  float A = dot(tang,tang) + 1.0;
  float B = -2.0 * dot(poc, tang);
  float C = dot(poc, poc) - 1.0;
  float a = (-B + sqrt(B * B - 4.0 * A * C)) / (2.0 * A);

  float2 uv = (point_ -a * sin_cos_angle.xy) / sin_cos_angle.zw;
  float r = FIX(R * acos(a));

  return uv * r / sin(r / R);
}

float3 maxscale() {
  float4 sin_cos_angle = (0.0, 0.0, 1.0, 1.0);

  float2 c = bkwtrans(
    -R * sin_cos_angle.xy / (1.0 + R / d * sin_cos_angle.z * sin_cos_angle.w)
  );

  float2 a = float2(0.5,0.5) * ASPECT;

  float2 lo = float2(
    fwtrans(float2(-a.x, c.y)).x,
    fwtrans(float2(c.x, -a.y)).y) / ASPECT;

  float2 hi = float2(
    fwtrans(float2(+a.x,c.y)).x,
    fwtrans(float2(c.x,+a.y)).y) / ASPECT;

  return float3((hi + lo) * ASPECT * 0.5, max(hi.x - lo.x, hi.y - lo.y));
}


#if defined(VERTEX)

void main(
  float2 TexCoord,
  float2 VertexCoord,
  float4 Color,

  uniform float4x4 MVPMatrix,

  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,
  float4 out oColor    : COLOR,
  float3 out stretch   : TEXCOORD1
) {
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
  oTexCoord = TexCoord;
  oColor = Color;

  stretch = maxscale();
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
  float2 TextureSize,
  float2 InputSize
) {

  float2 coord = uv;

  coord *= TextureSize / InputSize;
  coord = min(coord, float2(1.0) - coord) * ASPECT;

  float2 cdist = float2(0.03);
  coord = (cdist - min(coord,cdist));

  float dist = sqrt(dot(coord,coord));

  return clamp((cdist.x - dist) * 1000.0, 0.0, 1.0);
}

float2 transform(
  float2 coord,
  float2 TextureSize,
  float2 InputSize,
  float3 stretch
) {

  float2 uv = coord;

  uv *= TextureSize / InputSize;
  uv = (uv - float2(0.5)) * ASPECT * stretch.z + stretch.xy;

  return (bkwtrans(uv) / ASPECT + float2(0.5)) * InputSize / TextureSize;
}


void main(
  float2 TexCoord : TEXCOORD0,
  float3 stretch  : TEXCOORD1,

  uniform float2 TextureSize,
  uniform float2 OutputSize,
  uniform float2 InputSize,
  uniform sampler2D vTexture,

  float4 out oColor : COLOR
) {

  // float2 uv = TexCoord * (TextureSize / InputSize);
  // float vignette = uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);

  float2 uv = transform(
    TexCoord,
    TextureSize,
    InputSize,
    stretch
  );

  float4 color = crt_nes_mini(TextureSize, TexCoord, vTexture);

  // color.rgb = color.rgb * smoothstep(0, MAX, vignette);

  float mask = corner(uv, TextureSize, InputSize);
  color.rgb = color.rgb * float3(mask);

  oColor = color;
}

#endif