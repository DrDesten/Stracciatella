# Stracciatella
A very lightweight shader that keeps the vanilla style but addresses its shortcomings.  
It is highly configurable and lets you craft your own personal vanilla experience.  

<br>

## Feature Highlight
- Colored Block Light
- Colored Hand Light
- HDR Emissives
  - Generated Emissive Textures for Light Emitting Blocks
- Custom Fog and Sky
  - Shooting Stars
- Waving Blocks
- Custom Lightmap
  - Directional Lightmaps with Generated and Texture Normals
- Custom Color LUT support 
- Rain Refraction and Puddles
- Custom Block Outline

<br>

## Installation
Stracciatella requires Optifine or Iris to work.  
Stracciatella (with Optifine) supports Minecraft versions from 1.8.9 onwards.  

### Installation (Release) *Recommended*
Download the .zip file from the newest [release](https://github.com/DrDesten/Stracciatella/releases) and put it into your `.minecraft/shaderpacks` folder.  
You can now select the shader from within Minecraft. 

### Installation (Dev)
You need to have [git](https://git-scm.com/) and [NodeJS](https://nodejs.org/) installed.  
Open your terminal or command prompt in your `.minecraft/shaderpacks` folder.  
Run `git clone https://github.com/DrDesten/Stracciatella.git && cd Stracciatella` to clone the repository and navigate into it. It should contain `build` and `src` directories.  
Run `git submodule update --init --recursive` to download the required dependencies.  
Run `node build -f` to build the shader. A directory named `shaders` should be created.  
You can now select `Stracciatella` (same name as the folder) from within Minecraft.  

<br>

## Features

### Fog and Sky

[Gallery](https://modrinth.com/shader/stracciatella-shaders/gallery)

- Sun and Moon Size
- Sun Angle
- Horizon Cutoff for Sun and Moon
- Custom Stars
  - Size, Density, Coverage, Glow
- Shooting Stars
  - Direction, Density, Speed, Trail
- Fog Start and End
- Sky and Fog Colors
  - Sunset Colors
  - Sky and Fog Colors
    - Day, Night, Rain
  - End Sky Colors
- Cave Fog and Sky

### Lighting

- Custom Lightmap
  - Sky- and Blocklight AO
  - Sky- and Blocklight Gamma
  - Minimum Light
- Custom Lightmap Colors
  - Skylight
  - Complex Blocklight (Dark and Bright Color)
    - Blend Curve
- Directional Lightmaps
  - Generated and Texture Normals
- Colored Block and Hand Lights
  - Vibrance
- HDR Emissives

### Weather

- Rain Refraction
- Rain Opacity
- Angled Rain
  - Angle, Rotation Speed
- Rain Puddles
  - Coverage, Size, Opacity
  - Color

### Waving Blocks

- Waving Blocks / Liquids
  - Amount, Speed
- Waving Leaves
- Waving Lilypads
- Waving Lanters
- Waving Fire

### Camera and Color

- FXAA
- High Quality Sampling
- Contrast, Vibrance, Saturation, Brightness
- Vignette
  - Round, Square
- Color LUTs
  - Log Color, Cell Size

### Water

- Underwater Fog
  - Density, Depth Influence

### Utilities

- Blinking Ores
  - Blink Brightness
  - Diamond, Ancient Debris, Iron, Gold, Copper, Redstone, Lapis Lazuli, Coal, Nether Quarz, Nether Gold
- Damage Effect
  - Redness, Displacement, Cell Size

### Other

- Dithering
- World Time Animation
- Block Outline
  - Solid Outline
  - Line Thickness
  - Block Outline Styles
    - Black, White, Rainbow, Custom Color
