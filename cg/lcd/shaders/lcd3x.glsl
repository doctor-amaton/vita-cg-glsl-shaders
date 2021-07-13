/*
   Author: Gigaherz
   License: Public domain
*/

/* Non-retroarch output varyings for the fragment */
struct vertexOutput {
  float2 omega : TEXCOORD1;
};

#if defined(VERTEX)
void main (
  float2 TexCoord,
  float4 VertexCoord,

  uniform float2 TextureSize,
  uniform float4x4 MVPMatrix,

  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,

  vertexOutput out OUT
) {
    oPosition = mul(VertexCoord, MVPMatrix);
    oTexCoord = TexCoord;
    OUT.omega = 3.141592654 * 2 * TextureSize;
}

#elif defined(FRAGMENT)

/* configuration (higher values mean brighter image but reduced effect depth) */
/* TODO: Implement this using parameter uniforms */
static const int brighten_scanlines = 32;
static const int brighten_lcd = 12;

static const float3 offsets = 3.141592654 * float3(
  1.0 / 2,
  1.0 / 2 - 2.0 / 3,
  1.0 / 2 - 4.0 / 3
);

void main (
  vertexOutput OUT,
  float2 vTexCoord : TEXCOORD,
  uniform sampler2D vTexture,

  float4 out oColor : COLOR
) {
  float2 angle = vTexCoord * OUT.omega;
  float3 res = tex2D(vTexture, vTexCoord).xyz;

  float yFactor = (brighten_scanlines + sin(angle.y)) / (brighten_scanlines + 1);
  float3 xFactor = (brighten_lcd + sin(angle.x + offsets)) / (brighten_lcd + 1);

  float3 color = yFactor * xFactor * res;

  oColor = float4(color.x, color.y, color.z, 1.0);
}

#endif
