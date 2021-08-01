int GET_RESULT(float A, float B, float C, float D)
{
	int x = 0; int y = 0; int r = 0;
	if (A == C) x+=1; else if (B == C) y+=1;
	if (A == D) x+=1; else if (B == D) y+=1;
	if (x <= 1) r+=1; 
	if (y <= 1) r-=1;
	return r;
}
const static float3 dtt = float3(65536,255,1);
float reduce(half3 color)
{
	return dot(color, dtt);
}

#if defined(VERTEX)
void main(
  float2 TexCoord,
  float4 VertexCoord,
  float4 Color,
  uniform float2 TextureSize,
  uniform float4x4 MVPMatrix,
  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0,
  float4 out oTexCoord1 : TEXCOORD1,
  float4 out oTexCoord2 : TEXCOORD2,
  float4 out oTexCoord3 : TEXCOORD3,
  float4 out oTexCoord4 : TEXCOORD4,
  float4 out oTexCoord5 : TEXCOORD5,
  float4 out oTexCoord6 : TEXCOORD6,
  float4 out oTexCoord7 : TEXCOORD7,
  float4 out oTexCoord8 : TEXCOORD8)
{
	oPosition = mul(VertexCoord, MVPMatrix);

	float2 ps = float2(1.0/TextureSize.x, 1.0/TextureSize.y);
	float dx = ps.x;
	float dy = ps.y;

	oTexCoord = TexCoord; // E
	oTexCoord1.xy = TexCoord + half2(-dx,-dy);
	oTexCoord1.zw = TexCoord + half2(-dx,  0);
	oTexCoord2.xy = TexCoord + half2(+dx,-dy);
	oTexCoord2.zw = TexCoord + half2(+dx+dx,-dy);
	oTexCoord3.xy = TexCoord + half2(-dx,  0);
	oTexCoord3.zw = TexCoord + half2(+dx,  0);
	oTexCoord4.xy = TexCoord + half2(+dx+dx,  0);
	oTexCoord4.zw = TexCoord + half2(-dx,+dy);
	oTexCoord5.xy = TexCoord + half2(  0,+dy);
	oTexCoord5.zw = TexCoord + half2(+dx,+dy);
	oTexCoord6.xy = TexCoord + half2(+dx+dx,+dy);
	oTexCoord6.zw = TexCoord + half2(-dx,+dy+dy);
	oTexCoord7.xy = TexCoord + half2(  0,+dy+dy);
	oTexCoord7.zw = TexCoord + half2(+dx,+dy+dy);
	oTexCoord8.xy = TexCoord + half2(+dx+dx,+dy+dy);
}
#elif defined(FRAGMENT)
void main(
  uniform sampler2D decal,
  uniform float2 TextureSize,
  float2 TexCoord : TEXCOORD0,
  float4 oTexCoord1 : TEXCOORD1,
  float4 oTexCoord2 : TEXCOORD2,
  float4 oTexCoord3 : TEXCOORD3,
  float4 oTexCoord4 : TEXCOORD4,
  float4 oTexCoord5 : TEXCOORD5,
  float4 oTexCoord6 : TEXCOORD6,
  float4 oTexCoord7 : TEXCOORD7,
  float4 oTexCoord8 : TEXCOORD8,
  float4 out oColor : COLOR
)
{
   float2 fp = frac(TexCoord* TextureSize);
	// Reading the texels

	half3 C0 = tex2D(decal,oTexCoord1.xy).xyz; 
	half3 C1 = tex2D(decal,oTexCoord1.zw).xyz;
	half3 C2 = tex2D(decal,oTexCoord2.xy).xyz;
	half3 D3 = tex2D(decal,oTexCoord2.zw).xyz;
	half3 C3 = tex2D(decal,oTexCoord3.xy).xyz;
	half3 C4 = tex2D(decal,TexCoord).xyz;
	half3 C5 = tex2D(decal,oTexCoord3.zw).xyz;
	half3 D4 = tex2D(decal,oTexCoord4.xy).xyz;
	half3 C6 = tex2D(decal,oTexCoord4.zw).xyz;
	half3 C7 = tex2D(decal,oTexCoord5.xy).xyz;
	half3 C8 = tex2D(decal,oTexCoord5.zw).xyz;
	half3 D5 = tex2D(decal,oTexCoord6.xy).xyz;
	half3 D0 = tex2D(decal,oTexCoord6.zw).xyz;
	half3 D1 = tex2D(decal,oTexCoord7.xy).xyz;
	half3 D2 = tex2D(decal,oTexCoord7.zw).xyz;
	half3 D6 = tex2D(decal,oTexCoord8.xy).xyz;

	half3 p00,p10,p01,p11;

	// reducing half3 to float	
	float c0 = reduce(C0);float c1 = reduce(C1);
	float c2 = reduce(C2);float c3 = reduce(C3);
	float c4 = reduce(C4);float c5 = reduce(C5);
	float c6 = reduce(C6);float c7 = reduce(C7);
	float c8 = reduce(C8);float d0 = reduce(D0);
	float d1 = reduce(D1);float d2 = reduce(D2);
	float d3 = reduce(D3);float d4 = reduce(D4);
	float d5 = reduce(D5);float d6 = reduce(D6);

	/*              SuperEagle code               */
	/*  Copied from the Dosbox source code        */
	/*  Copyright (C) 2002-2007  The DOSBox Team  */
	/*  License: GNU-GPL                          */
	/*  Adapted by guest(r) on 16.4.2007          */       
	if (c4 != c8) {
		if (c7 == c5) {
			p01 = p10 = C7;
			if ((c6 == c7) || (c5 == c2)) {
					p00 = 0.25*(3.0*C7+C4);
			} else {
					p00 = 0.5*(C4+C5);
			}

			if ((c5 == d4) || (c7 == d1)) {
					p11 = 0.25*(3.0*C7+C8);
			} else {
					p11 = 0.5*(C7+C8);
			}
		} else {
			p11 = 0.125*(6.0*C8+C7+C5);
			p00 = 0.125*(6.0*C4+C7+C5);

			p10 = 0.125*(6.0*C7+C4+C8);
			p01 = 0.125*(6.0*C5+C4+C8);
		}
	} else {
		if (c7 != c5) {
			p11 = p00 = C4;

			if ((c1 == c4) || (c8 == d5)) {
					p01 = 0.25*(3.0*C4+C5);
			} else {
					p01 = 0.5*(C4+C5);
			}

			if ((c8 == d2) || (c3 == c4)) {
					p10 = 0.25*(3.0*C4+C7);
			} else {
					p10 = 0.5*(C7+C8);
			}
		} else {
			int r = 0;
			r += GET_RESULT(c5,c4,c6,d1);
			r += GET_RESULT(c5,c4,c3,c1);
			r += GET_RESULT(c5,c4,d2,d5);
			r += GET_RESULT(c5,c4,c2,d4);

			if (r > 0) {
					p01 = p10 = C7;
					p00 = p11 = 0.5*(C4+C5);
			} else if (r < 0) {
					p11 = p00 = C4;
					p01 = p10 = 0.5*(C4+C5);
			} else {
					p11 = p00 = C4;
					p01 = p10 = C7;
			}
		}
	}



	// Distributing the four products

	p10 = (fp.x < 0.50) ? (fp.y < 0.50 ? p00 : p10) : (fp.y < 0.50 ? p01: p11);

	// OUTPUT
	oColor = float4(p10, 1);
}
#endif