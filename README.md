# Future deprecation notice
I left this project unattended and new developments on the Vita scene have arrived since, particularly Pigs-in-a-blanket being deprecated in favor of https://github.com/GrapheneCt/PVR_PSP2

I'm currently working on a PR that will integrate PVR_PSP2 into Retroarch itself, which will mean that you'll be able to use GLSL shaders as you normally would, and no longer require to download this repo's CG shaders.

# If you can't see any shader preset options
There seems to be an issue with Retroarch itself which will not show you items in the search feature if a Shader folder hasn't been set in the configuration. To fix this, just choose the folder in settings where you downloaded this repo, for example: `ux0/data/retroarch/shaders/vita-cg-glsl-shaders/cg` and then the items will show up automatically when you navigate to shader options.

# Retroarch vita-cg-glsl-shaders
A collection of shaders for RetroArch that were ported from CG / GLSL to be compliant with the ShaccCg shader compiler.

## Why not use the already available CG shaders
There's many differences between how libCg and ShaccCg work under the hood that it's not practical to just patch RetroArch to support loading CG preset files.
For example there's no support for `\#include` upon which all of CG shaders rely on to manage compatibility between HLSL and regular CG, as well as macros.
It's easier to just port them to this format instead.

## How to use?
You need to install the Pigs-in-a-Blanket build of RetroArch. Then you can just copy all of the contents of this repo to your `ux0/data/retroarch/shaders`
folder and they should appear and apply correctly. If they don't please make sure you're running the correct RetroArch build, and if they still don't work
let me know by filing an issue here.

## Why are the shaders named glsl instead of cg?
In order to trick RetroArch into loading them as if they were glsl shaders. That's currently the best approach and I think it's for the best,
to avoid having confusion as to why no CG shaders work at all...

## Who should I thank for this?
Well naturally @SonicMastr, @frangarcj, @OsirizX, @hizzlekizzle and everyone else who helped out in getting ShaccCg support as well as implementing
all of the necessary changes in RetroArch to get it working!
