/*
   Scale2xPlus shader 

   - Copyright (C) 2007 guest(r) - guest.r@gmail.com

   - License: GNU-GPL  


   The Scale2x algorithm:

   - Scale2x Homepage: http://scale2x.sourceforge.net/

   - Copyright (C) 2001, 2002, 2003, 2004 Andrea Mazzoleni 

   - License: GNU-GPL  

 */
#if defined(VERTEX)
void main(
  uniform float2 TextureSize,
  float2 TexCoord,
  float4 VertexCoord,
  uniform float4x4 MVPMatrix,
  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,
  float4 out ot1 : TEXCOORD1,
  float4 out ot2 : TEXCOORD2)
{
	oPosition = mul(VertexCoord, MVPMatrix);

	float2 ps = float2(1.0/TextureSize.x, 1.0/TextureSize.y);
	float dx = ps.x;
	float dy = ps.y;

	oTexCoord = TexCoord; // E
	ot1 = TexCoord.xyxy + float4(  0,-dy,-dx,  0); // B, D
	ot2 = TexCoord.xyxy + float4( dx,  0,  0, dy); // F
}
#elif defined(FRAGMENT)
void main(
  uniform sampler2D decal,
  uniform float2 TextureSize,
  float2 TexCoord : TEXCOORD0,
  float4 t1 : TEXCOORD1,
  float4 t2 : TEXCOORD2,
  float4 out oColor : COLOR 
)
{
	float2 fp = frac(TexCoord* TextureSize);

	// Reading the texels

	float3 B = tex2D(decal, t1.xy).xyz;
	float3 D = tex2D(decal, t1.zw).xyz;
	float3 E = tex2D(decal, TexCoord).xyz;
	float3 F = tex2D(decal, t2.xy).xyz;
	float3 H = tex2D(decal, t2.zw).xyz;

	float3 E0 = D == B && B != H && D != F ? D : E;
	float3 E1 = B == F && B != H && D != F ? F : E;
	float3 E2 = D == H && B != H && D != F ? D : E;
	float3 E3 = H == F && B != H && D != F ? F : E;

	// Product interpolation
	oColor = float4((E3*fp.x+E2*(1-fp.x))*fp.y+(E1*fp.x+E0*(1-fp.x))*(1-fp.y),1);
}
#endif