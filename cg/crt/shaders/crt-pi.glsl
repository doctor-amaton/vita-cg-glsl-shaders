/*
    crt-pi - A Raspberry Pi friendly CRT shader.

    Copyright (C) 2015-2016 davej

    Ported to CG by doctor-amaton

    This program is free software; you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by the Free
    Software Foundation; either version 2 of the License, or (at your option)
    any later version.


    Notes:

    This shader is designed to work well on Raspberry Pi GPUs (i.e. 1080P @ 60Hz on a game with a 4:3 aspect ratio). It pushes the Pi's GPU hard and enabling some features will slow it down so that it is no longer able to match 1080P @ 60Hz. You will need to overclock your Pi to the fastest setting in raspi-config to get the best results from this shader: 'Pi2' for Pi2 and 'Turbo' for original Pi and Pi Zero. Note: Pi2s are slower at running the shader than other Pis, this seems to be down to Pi2s lower maximum memory speed. Pi2s don't quite manage 1080P @ 60Hz - they drop about 1 in 1000 frames. You probably won't notice this, but if you do, try enabling FAKE_GAMMA.

    SCANLINES enables scanlines. You'll almost certainly want to use it with MULTISAMPLE to reduce moire effects. SCANLINE_WEIGHT defines how wide scanlines are (it is an inverse value so a higher number = thinner lines). SCANLINE_GAP_BRIGHTNESS defines how dark the gaps between the scan lines are. Darker gaps between scan lines make moire effects more likely.

    GAMMA enables gamma correction using the values in INPUT_GAMMA and OUTPUT_GAMMA. FAKE_GAMMA causes it to ignore the values in INPUT_GAMMA and OUTPUT_GAMMA and approximate gamma correction in a way which is faster than true gamma whilst still looking better than having none. You must have GAMMA defined to enable FAKE_GAMMA.

    CURVATURE distorts the screen by CURVATURE_X and CURVATURE_Y. Curvature slows things down a lot.

    By default the shader uses linear blending horizontally. If you find this too blury, enable SHARPER.

    BLOOM_FACTOR controls the increase in width for bright scanlines.

    MASK_TYPE defines what, if any, shadow mask to use. MASK_BRIGHTNESS defines how much the mask type darkens the screen.

*/

#pragma parameter CURVATURE_X "Screen curvature - horizontal" 0.10 0.0 1.0 0.01
#pragma parameter CURVATURE_Y "Screen curvature - vertical" 0.15 0.0 1.0 0.01
#pragma parameter MASK_BRIGHTNESS "Mask brightness" 0.70 0.0 1.0 0.01
#pragma parameter SCANLINE_WEIGHT "Scanline weight" 6.0 0.0 15.0 0.1
#pragma parameter SCANLINE_GAP_BRIGHTNESS "Scanline gap brightness" 0.12 0.0 1.0 0.01
#pragma parameter BLOOM_FACTOR "Bloom factor" 1.5 0.0 5.0 0.01
#pragma parameter INPUT_GAMMA "Input gamma" 2.4 0.0 5.0 0.01
#pragma parameter OUTPUT_GAMMA "Output gamma" 2.2 0.0 5.0 0.01


#ifdef PARAMETER_UNIFORM
uniform float CURVATURE_X;
uniform float CURVATURE_Y;
uniform float MASK_BRIGHTNESS;
uniform float SCANLINE_WEIGHT;
uniform float SCANLINE_GAP_BRIGHTNESS;
uniform float BLOOM_FACTOR;
uniform float INPUT_GAMMA;
uniform float OUTPUT_GAMMA;

#else
#define CURVATURE_X 0.10
#define CURVATURE_Y 0.25
#define MASK_BRIGHTNESS 0.70
#define SCANLINE_WEIGHT 6.0
#define SCANLINE_GAP_BRIGHTNESS 0.12
#define BLOOM_FACTOR 1.5
#define INPUT_GAMMA 2.4
#define OUTPUT_GAMMA 2.2

#endif

// Haven't put these as parameters as it would slow the code down.
#define SCANLINES
#define MULTISAMPLE
#define GAMMA
#define CURVATURE
//#define FAKE_GAMMA
//#define SHARPER

#define MASK_TYPE 1 /* MASK_TYPE: 0 = none, 1 = green/magenta, 2 = trinitron(ish) */

#if defined(VERTEX)

void main(
  float2 TexCoord,
  float2 VertexCoord,

  uniform float4x4 MVPMatrix,

  uniform float2 TextureSize,
  uniform float2 InputSize,
  uniform float2 OutputSize,

  float4 out screenScaleFilterWidth : TEXCOORD1,
  float4 out oPosition : POSITION,
  float2 out oTexCoord : TEXCOORD0
) {

  #if defined(CURVATURE)
    screenScaleFilterWidth.xy = TextureSize / InputSize;
  #endif

  screenScaleFilterWidth.zw = (InputSize.y / OutputSize.y) / 3.0;
  oTexCoord = TexCoord;
  oPosition = mul(float4(VertexCoord, 0.0, 1.0), MVPMatrix);
}

#elif defined(FRAGMENT)

  #if defined(CURVATURE)

    float2 Distort(float2 coord, float2 screenScale) {
      float2 CURVATURE_DISTORTION = float2(CURVATURE_X, CURVATURE_Y);

      // Barrel distortion shrinks the display area a bit,
      // this will allow us to counteract that.
      float2 barrelScale = 1.0 - (0.23 * CURVATURE_DISTORTION);

      coord *= screenScale;
      coord -= float2(0.5);

      float rsq = coord.x * coord.x + coord.y * coord.y;

      coord += coord * (CURVATURE_DISTORTION * rsq);
      coord *= barrelScale;

      if (abs(coord.x) >= 0.5 || abs(coord.y) >= 0.5) {
        coord = float2(-1.0);   // If out of bounds, return an invalid value.

      } else {
        coord += float2(0.5);
        coord /= screenScale;
      }

      return coord;
    }

  #endif

  float CalcScanLineWeight(float dist) {
    return max(1.0 - dist * dist * SCANLINE_WEIGHT, SCANLINE_GAP_BRIGHTNESS);
  }

  float CalcScanLine(float dy, float2 filterWidth) {
    float scanLineWeight = CalcScanLineWeight(dy);

    #if defined(MULTISAMPLE)

      scanLineWeight += CalcScanLineWeight(dy - filterWidth);
      scanLineWeight += CalcScanLineWeight(dy + filterWidth);
      scanLineWeight *= 0.3333333;

    #endif

    return scanLineWeight;
  }


  void main(
    float2 TexCoord : TEXCOORD0,
    float4 screenScaleFilterWidth : TEXCOORD1,

    uniform float2 TextureSize,
    uniform float2 OutputSize,
    uniform sampler2D vTexture,

    float4 out oColor : COLOR
  ) {
    float2 screenScale = screenScaleFilterWidth.xy;
    float2 filterWidth = screenScaleFilterWidth.zw;

    float2 retroGlFragCoord = TexCoord * OutputSize.xy;

    #if defined(CURVATURE)

      float2 uv = Distort(TexCoord, screenScale);

      if (uv.x < 0.0) {
        oColor = float4(0.0); /* TODO: Implement vignette to prevent aliasing */

      } else {
        float2 uv = TexCoord;
      }

    #else

      float2 uv = TexCoord;

    #endif

    float2 texcoordInPixels = uv * TextureSize;

    #if defined(SHARPER)

      float2 tempCoord = floor(texcoordInPixels) + 0.5;
      float2 coord = tempCoord / TextureSize;
      float2 deltas = texcoordInPixels - tempCoord;
      float2 signs = sign(deltas);

      float scanLineWeight = CalcScanLine(deltas.y, filterWidth);

      deltas.x *= 2.0;
      deltas = deltas * deltas;
      deltas.y = deltas.y * deltas.y;
      deltas.x *= 0.5;
      deltas.y *= 8.0;
      deltas /= TextureSize;
      deltas *= signs;

      float2 tc = coord + deltas;

    #else

      float tempY = floor(texcoordInPixels.y) + 0.5;
      float yCoord = tempY / TextureSize.y;
      float dy = texcoordInPixels.y - tempY;
      float scanLineWeight = CalcScanLine(dy, filterWidth);
      float signY = sign(dy);

      dy = dy * dy;
      dy = dy * dy;
      dy *= 8.0;
      dy /= TextureSize.y;
      dy *= signY;

      float2 tc = float2(uv.x, yCoord + dy);

    #endif

    float3 colour = tex2D(vTexture, tc).rgb;

    #if defined(SCANLINES)
      #if defined(GAMMA)
        #if defined(FAKE_GAMMA)
          colour = colour * colour;
        #else
          colour = pow(colour, float3(INPUT_GAMMA));
        #endif
      #endif

      scanLineWeight *= BLOOM_FACTOR;
      colour *= scanLineWeight;

      #if defined(GAMMA)
        #if defined(FAKE_GAMMA)
          colour = sqrt(colour);
        #else
          colour = pow(colour, float3(1.0/OUTPUT_GAMMA));
        #endif
      #endif
    #endif

    #if MASK_TYPE == 0
      oColor = float4(colour, 1.0);
    #else

    #if MASK_TYPE == 1
      float whichMask = frac(retroGlFragCoord.x * 0.5);
      float3 mask;

      if (whichMask < 0.5) {
        mask = float3(MASK_BRIGHTNESS, 1.0, MASK_BRIGHTNESS);
      }
      else {
        mask = float3(1.0, MASK_BRIGHTNESS, 1.0);
      }

    #elif MASK_TYPE == 2

      float whichMask = frac(retroGlFragCoord.x * 0.3333333);
      float3 mask = float3(MASK_BRIGHTNESS, MASK_BRIGHTNESS, MASK_BRIGHTNESS);

      if (whichMask < 0.3333333) {
        mask.x = 1.0;

      } else if (whichMask < 0.6666666) {
        mask.y = 1.0;

      } else {
        mask.z = 1.0;
      }

    #endif

    oColor = float4(colour * mask, 1.0);

    #endif
  }

#endif
