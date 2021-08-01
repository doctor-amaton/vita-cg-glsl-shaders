/*

   Copyright (C) 2007 guest(r) - guest.r@gmail.com

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#if defined(VERTEX)
void main(
  float2 TexCoord,
  float2 VertexCoord,
  float4 Color,
  uniform float4x4 MVPMatrix,
  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0)
{
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
  oTexCoord = TexCoord;
}
#elif defined(FRAGMENT)
void main(
  uniform sampler2D vTexture,
  uniform float2 TextureSize,
  float2 TexCoord : TEXCOORD0,
  float4 out oColor : COLOR
)
{
   float2 texsize = float4(TextureSize, 1.0 / TextureSize).xy;
   float dx = pow(texsize.x, -1.0) * 0.25;
   float dy = pow(texsize.y, -1.0) * 0.25;
   float3 dt = float3(1.0, 1.0, 1.0);

   float3 c00 = tex2D(vTexture, TexCoord + float2(-dx, -dy)).xyz;
   float3 c20 = tex2D(vTexture, TexCoord + float2(dx, -dy)).xyz;
   float3 c02 = tex2D(vTexture, TexCoord + float2(-dx, dy)).xyz;
   float3 c22 = tex2D(vTexture, TexCoord + float2(dx, dy)).xyz;

   float m1=dot(abs(c00-c22),dt)+0.001;
   float m2=dot(abs(c02-c20),dt)+0.001;

   oColor = float4((m1*(c02+c20)+m2*(c22+c00))/(2.0*(m1+m2)),1.0);
}
#endif