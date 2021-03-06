/*
    CRT-interlaced

    Copyright (C) 2010-2012 cgwg, Themaister and DOLLS

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.

    (cgwg gave their consent to have the original version of this shader
    distributed under the GPL in this message:

        http://board.byuu.org/viewtopic.php?p=26075#p26075

        "Feel free to distribute my shaders under the GPL. After all, the
        barrel distortion code was taken from the Curvature shader, which is
        under the GPL."
    )
	This shader variant is pre-configured with screen curvature
*/

#pragma parameter CRTgamma "CRTGeom Target Gamma" 2.4 0.1 5.0 0.1
#pragma parameter monitorgamma "CRTGeom Monitor Gamma" 2.2 0.1 5.0 0.1
#pragma parameter d "CRTGeom Distance" 1.5 0.1 3.0 0.1
#pragma parameter R "CRTGeom Curvature Radius" 2.0 0.1 10.0 0.1
#pragma parameter cornersize "CRTGeom Corner Size" 0.03 0.001 1.0 0.005
#pragma parameter cornersmooth "CRTGeom Corner Smoothness" 1000.0 80.0 2000.0 100.0
#pragma parameter x_tilt "CRTGeom Horizontal Tilt" 0.0 -0.5 0.5 0.05
#pragma parameter y_tilt "CRTGeom Vertical Tilt" 0.0 -0.5 0.5 0.05
#pragma parameter overscan_x "CRTGeom Horiz. Overscan %" 100.0 -125.0 125.0 1.0
#pragma parameter overscan_y "CRTGeom Vert. Overscan %" 100.0 -125.0 125.0 1.0
#pragma parameter DOTMASK "CRTGeom Dot Mask Toggle" 0.3 0.0 0.3 0.3
#pragma parameter scanline_weight "CRTGeom Scanline Weight" 0.3 0.1 0.5 0.01
#pragma parameter lum "CRTGeom Luminance Boost" 0.0 0.0 1.0 0.01
#pragma parameter interlace_toggle "CRTGeom Interlacing" 1.0 1.0 5.0 4.0

#ifdef PARAMETER_UNIFORM
uniform float CRTgamma;
uniform float monitorgamma;
uniform float d;
uniform float R;
uniform float cornersize;
uniform float cornersmooth;
uniform float x_tilt;
uniform float y_tilt;
uniform float overscan_x;
uniform float overscan_y;
uniform float DOTMASK;
uniform float scanline_weight;
uniform float lum;
uniform float interlace_toggle;

#else
#define CRTgamma 2.4
#define monitorgamma 2.2
#define d 1.5
#define R 2.0
#define cornersize 0.03
#define cornersmooth 1000.0
#define x_tilt 0.0
#define y_tilt 0.0
#define overscan_x 100.0
#define overscan_y 100.0
#define DOTMASK 0.3
#define scanline_weight 0.3
#define lum 0.0
#define interlace_toggle 1.0

#endif

#define mod(x,y) (x - y * trunc(x/y))

// Comment the next line to disable interpolation in linear gamma (and gain speed)
// #define LINEAR_PROCESSING

// Use the older, purely gaussian beam profile; uncomment for speed
#define USEGAUSSIAN

// Enable 3x oversampling of the beam profile; improves moire effect caused by scanlines + curvature
#define OVERSAMPLE

// Use interlacing detection; may interfere with other shaders if combined
#define INTERLACED

// Macros
#define FIX(c) max(abs(c), 1e-5);
#define PI 3.141592653589

#ifdef LINEAR_PROCESSING
#define TEX2D(c) pow(tex2D(s0, (c)), float4(CRTgamma,CRTgamma,CRTgamma,CRTgamma))
#else
#define TEX2D(c) tex2D(s0, (c))
#endif

// Aspect ratio
static float2 aspect = float2(1.0, 0.75);

float intersect(float2 xy, float4 sin_cos_angle)
{
  float A = dot(xy, xy) + d * d;
  float B = 2.0 * (R * (dot(xy, sin_cos_angle.xy) - d * sin_cos_angle.zw.x * sin_cos_angle.zw.y) - d * d);
  float C = d * d + 2.0 * R * d * sin_cos_angle.zw.x * sin_cos_angle.zw.y;
  return (-B - sqrt(B * B - 4.0 * A * C)) / (2.0 * A);
}

float2 bkwtrans(float2 xy, float4 sin_cos_angle)
{
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

float2 fwtrans(float2 uv, float4 sin_cos_angle)
{
  float r = FIX(sqrt(dot(uv,uv)));
  uv *= sin(r/R)/r;
  float x = 1.0-cos(r/R);
  float D = d/R + x*sin_cos_angle.z*sin_cos_angle.w+dot(uv,sin_cos_angle.xy);
  return d*(uv*sin_cos_angle.zw-x*sin_cos_angle.xy)/D;
}

float3 maxscale(float4 sin_cos_angle)
{
  float2 c = bkwtrans(-R * sin_cos_angle.xy / (1.0 + R/d*sin_cos_angle.z*sin_cos_angle.w), sin_cos_angle);
  float2 a = float2(0.5,0.5)*aspect;
  float2 lo = float2(
    fwtrans(float2(-a.x,c.y), sin_cos_angle).x,
    fwtrans(float2(c.x,-a.y), sin_cos_angle).y) / aspect;

  float2 hi = float2(
    fwtrans(float2(+a.x,c.y), sin_cos_angle).x,
    fwtrans(float2(c.x,+a.y), sin_cos_angle).y) / aspect;

  return float3((hi + lo) * aspect * 0.5, max(hi.x - lo.x, hi.y - lo.y));
}

struct out_vertex {
  // Additional outputs to guide the frag
  float4 mod_factor_stretch : TEXCOORD1;
  float4 ilfac_one : TEXCOORD2;
	float4 sin_cos_angle : TEXCOORD3;
};

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

  out_vertex out OUT
) {

	oColor = Color;
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
  oTexCoord = TexCoord;

  // Precalculate a bunch of useful values we'll need in the fragment shader
  float2 sinangle = sin(float2(x_tilt, y_tilt));
  float2 cosangle = cos(float2(x_tilt, y_tilt));

  OUT.sin_cos_angle = float4(
    sinangle.x,
    sinangle.y,
    cosangle.x,
    cosangle.y
  );

  OUT.mod_factor_stretch.x = TexCoord.x * TextureSize.x * OutputSize.x / InputSize.x;
  OUT.mod_factor_stretch.yzw = maxscale(OUT.sin_cos_angle);

  OUT.ilfac_one.xy = float2(1.0, clamp(floor(InputSize.y / (200.0 * interlace_toggle)), 1.0, 2.0));

  // The size of one texel, in texture-coordinates.
  OUT.ilfac_one.zw = OUT.ilfac_one.xy / TextureSize;
}

#elif defined(FRAGMENT)

/*
  Calculate the influence of a scanline on the current pixel.

  'distance' is the distance in texture coordinates from the current pixel to the scanline in question.
  'color' is the colour of the scanline at the horizontal location of the current pixel.
  'wid' controls the width of the scanline beam, for each RGB channel

  The 'weights' lines basically specify the formula that gives you the profile of the beam,
  i.e. the intensity as a function of distance from the vertical center of the
  scanline. In this case, it is gaussian if width=2, and becomes nongaussian for larger widths.

  Ideally this should be normalized so that the integral across the beam is
  independent of its width. That is, for a narrower beam 'weights' should have a higher peak at
  the center of the scanline than for a wider beam.
*/
float4 scanlineWeights(float distance, float4 color)
{
  #ifdef USEGAUSSIAN
    float4 wid = 0.3 + 0.1 * pow(color, float4(3.0, 3.0, 3.0, 3.0));
    float v = distance / (wid * scanline_weight/0.3);
    float4 weights = float4(v,v,v,v);
    return (lum + 0.4) * exp(-weights * weights) / wid;
  #else
    float4 wid = 2.0 + 2.0 * pow(color, float4(4.0, 4.0, 4.0, 4.0));
    float v = distance / scanline_weight;
    float4 weights = float4(v,v,v,v);
    return (lum + 1.4) * exp(-pow(weights * rsqrt(0.5 * wid), wid)) / (0.6 + 0.2 * wid);
  #endif
}

float4 crt_geom(float2 texture_size, float2 video_size, float2 output_size, float frame_count, float4 sin_cos_angle, float3 stretch,
	float2 ilfac, float2 one, float mod_factor, float2 TextureSize, float2 texCoord, sampler2D s0)
{
  // Here's a helpful diagram to keep in mind while trying to
  // understand the code:
  //
  //  |      |      |      |      |
  // -------------------------------
  //  |      |      |      |      |
  //  |  01  |  11  |  21  |  31  | <-- current scanline
  //  |      | @    |      |      |
  // -------------------------------
  //  |      |      |      |      |
  //  |  02  |  12  |  22  |  32  | <-- next scanline
  //  |      |      |      |      |
  // -------------------------------
  //  |      |      |      |      |
  //
  // Each character-cell represents a pixel on the output
  // surface, "@" represents the current pixel (always somewhere
  // in the bottom half of the current scan-line, or the top-half
  // of the next scanline). The grid of lines represents the
  // edges of the texels of the underlying texture.

  // Texture coordinates of the texel containing the active pixel.
	float2 xy = 0.0;
  float2 cd = texCoord;
  cd *= texture_size / video_size;
  cd = (cd-float2(0.5, 0.5))*aspect*stretch.z+stretch.xy;
  xy =  (bkwtrans(cd, sin_cos_angle)/float2(overscan_x / 100.0, overscan_y / 100.0)/aspect+float2(0.5, 0.5)) * video_size / texture_size;

  float2 cd2 = xy;
  cd2 *= texture_size / video_size;
  cd2 = (cd2 - float2(0.5, 0.5)) * float2(overscan_x / 100.0, overscan_y / 100.0) + float2(0.5, 0.5);
  cd2 = min(cd2, float2(1.0, 1.0)-cd2) * aspect;
  float2 cdist = float2(cornersize, cornersize);
  cd2 = (cdist - min(cd2,cdist));
  float dist = sqrt(dot(cd2,cd2));
  float cval = clamp((cdist.x-dist)*cornersmooth,0.0, 1.0);

  float2 xy2 = ((xy*TextureSize/video_size-float2(0.5, 0.5))*float2(1.0,1.0)+float2(0.5, 0.5))*video_size/TextureSize;
  // Of all the pixels that are mapped onto the texel we are
  // currently rendering, which pixel are we currently rendering?
  float2 ilfloat = float2(0.0,ilfac.y > 1.5 ? mod(float(frame_count),2.0) : 0.0);

  float2 ratio_scale = (xy * TextureSize - float2(0.5,0.5) + ilfloat)/ilfac;

  #ifdef OVERSAMPLE
    float filter = video_size.y / output_size.y;
  #endif

  float2 uv_ratio = frac(ratio_scale);

  // Snap to the center of the underlying texel.
  xy = (floor(ratio_scale)*ilfac + float2(0.5, 0.5) - ilfloat) / TextureSize;

  // Calculate Lanczos scaling coefficients describing the effect
  // of various neighbour texels in a scanline on the current
  // pixel.
  float4 coeffs = PI * float4(1.0 + uv_ratio.x, uv_ratio.x, 1.0 - uv_ratio.x, 2.0 - uv_ratio.x);

  // Prevent division by zero.
  coeffs = FIX(coeffs);

  // Lanczos2 kernel.
  coeffs = 2.0 * sin(coeffs) * sin(coeffs / 2.0) / (coeffs * coeffs);

  // Normalize.
  coeffs /= dot(coeffs, float4(1.0, 1.0, 1.0, 1.0));

  // Calculate the effective colour of the current and next
  // scanlines at the horizontal location of the current pixel,
  // using the Lanczos coefficients above.
    float4 col  = clamp(mul(coeffs, float4x4(
      TEX2D(xy + float2(-one.x, 0.0)),
      TEX2D(xy),
      TEX2D(xy + float2(one.x, 0.0)),
      TEX2D(xy + float2(2.0 * one.x, 0.0)))),
    0.0, 1.0);

  float4 col2 = clamp(mul(coeffs, float4x4(
    TEX2D(xy + float2(-one.x, one.y)),
    TEX2D(xy + float2(0.0, one.y)),
    TEX2D(xy + one),
    TEX2D(xy + float2(2.0 * one.x, one.y)))),
  0.0, 1.0);

  #ifndef LINEAR_PROCESSING
    col  = pow(col , float4(CRTgamma));
    col2 = pow(col2, float4(CRTgamma));
  #endif

  // Calculate the influence of the current and next scanlines on
  // the current pixel.
  float4 weights  = scanlineWeights(uv_ratio.y, col);
  float4 weights2 = scanlineWeights(1.0 - uv_ratio.y, col2);

  #ifdef OVERSAMPLE
    uv_ratio.y =uv_ratio.y+1.0/3.0*filter;
    weights = (weights+scanlineWeights(uv_ratio.y, col))/3.0;
    weights2=(weights2+scanlineWeights(abs(1.0-uv_ratio.y), col2))/3.0;
    uv_ratio.y =uv_ratio.y-2.0/3.0*filter;
    weights=weights+scanlineWeights(abs(uv_ratio.y), col)/3.0;
    weights2=weights2+scanlineWeights(abs(1.0-uv_ratio.y), col2)/3.0;
  #endif

  float3 mul_res  = (col * weights + col2 * weights2).rgb;
  mul_res *= float3(cval, cval, cval);

  // dot-mask emulation:
  // Output pixels are alternately tinted green and magenta.
  float3 dotMaskWeights = lerp(
    float3(1.0, 1.0 - DOTMASK, 1.0),
    float3(1.0 - DOTMASK, 1.0, 1.0 - DOTMASK),
    floor(mod(mod_factor, 2.0))
  );

  mul_res *= dotMaskWeights;

  // Convert the image gamma for display on our output device.
  mul_res = pow(mul_res, float3(1.0 / monitorgamma, 1.0 / monitorgamma, 1.0 / monitorgamma));

  // Color the texel.
  return float4(mul_res, 1.0);
}

void main(
  out_vertex VOUT,
  uniform sampler2D vTexture,
  uniform float2 TextureSize,
  uniform float2 InputSize,
  uniform float2 OutputSize,
  uniform int FrameCount,

  float2 TexCoord : TEXCOORD0,
  float4 Color : COLOR,
  float4 out oColor : COLOR
) {
	oColor = crt_geom(
    TextureSize,
    InputSize,
    OutputSize,
    FrameCount,

    VOUT.sin_cos_angle,
    VOUT.mod_factor_stretch.yzw,
	  VOUT.ilfac_one.xy,
    VOUT.ilfac_one.zw,
    VOUT.mod_factor_stretch.x,
    TextureSize,
    TexCoord,

    vTexture
  );
}
#endif
