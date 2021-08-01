/*
   Author: rsn8887 (based on TheMaister)
   License: Public domain

   This is an integer prescale filter that should be combined
   with a bilinear hardware filtering (GL_BILINEAR filter or some such) to achieve
   a smooth scaling result with minimum blur. This is good for pixelgraphics
   that are scaled by non-integer factors.
   
   The prescale factor and texel coordinates are precalculated
   in the vertex shader for speed.
*/

#if defined(VERTEX)
void main(
  float2 TexCoord,
  float2 VertexCoord,
  uniform float4x4 MVPMatrix,
  uniform float2 TextureSize,
  uniform float2 InputSize,
  uniform float2 OutputSize,
  out float4 oPosition : POSITION,
  out float2 oTexCoord : TEXCOORD0,
  out float2 texel : TEXCOORD1,
  out float2 scale : TEXCOORD2)
{
    oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
    oTexCoord = TexCoord;
    texel = TexCoord * float4(TextureSize, 1.0 / TextureSize).xy;
    scale = max(floor(float4(OutputSize, 1.0 / OutputSize).xy / InputSize.xy), float2(1.0, 1.0));
}
#elif defined(FRAGMENT)
void main(
  uniform sampler2D vTexture,
  uniform float2 TextureSize,
  float2 TexCoord : TEXCOORD0,
  float2 texel : TEXCOORD1,
  float2 scale : TEXCOORD2,
  float4 out oColor : COLOR
)
{
   float2 texel_floored = floor(texel);
   float2 s = frac(texel);
   float2 region_range = 0.5 - 0.5 / scale;

   // Figure out where in the texel to sample to get correct pre-scaled bilinear.
   // Uses the hardware bilinear interpolator to avoid having to sample 4 times manually.

   float2 center_dist = s - 0.5;
   float2 f = (center_dist - clamp(center_dist, -region_range, region_range)) * scale + 0.5;

   float2 mod_texel = texel_floored + f;

   oColor = float4(tex2D(vTexture, mod_texel / float4(TextureSize, 1.0 / TextureSize).xy).rgb, 1.0);
}
#endif