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

 - Fog - *OFF, Border, Auto, Advanced*  
&emsp;Border:  
&emsp;Simple, comparable to vanilla  
&emsp;Auto:  
&emsp;Enables "Advanced" fog when Distant Horizons is present  
&emsp;Advanced:  
&emsp;Border fog aswell as configurable exponential distance and height based fog
 - **Advanced Fog**
   - Global Fog Density  
&emsp;Constant fog density applied to exponential fog  
&emsp;Overworld, Nether and End densities are relative to this value
   - Overworld Fog Density  
&emsp;Density of constant Overworld fog  
&emsp;Relative to "Global Density"
   - Overworld Noise Fog
   - **Overworld**
     - Height Scale Multiplier  
&emsp;Multiplier applied to the scale factor used to calculate height fog  
&emsp;Higher values correspond to a harsher density falloff
     - Height Density Multiplier  
&emsp;Multiplier applied to the density calculated from world height
     - Dynamic Density Start Height  
&emsp;Fog density starts to increase with player height after the selected world height  
&emsp;Set to the default value, this acts as a correctional factor to keep the fog density (visually) constant
     - Dynamic Density Multiplier  
&emsp;Controls how much player height influences fog density
     - Anisotropic Sunset Fog  
&emsp;Fog density at sunset and sunrise increases more in direction of the sun
     - Sunset Fog Anisotropy  
&emsp;Amount of Anisotropy
     - Sunset Fog Multiplier  
&emsp;Controls how much the fog changes during sunset and sunrise
     - Wind Speed
     - Noise Fog Scale
     - Noise Fog Fade
     - Noise Fog Density Multiplier
   - Nether Fog Density  
&emsp;Density of constant Nether fog  
&emsp;Relative to "Global Density"
   - Nether Noise Fog
   - **Nether**
     - Wind Speed
     - Noise Fog Scale
     - Noise Fog Fade
     - Near Fog Density Multiplier
   - End Fog Density  
&emsp;Density of constant End fog  
&emsp;Relative to "Global Density"
   - **End**
 - Fog Start  
&emsp;Sets where the fog starts appearing  
&emsp;Relative to render distance
 - Fog End  
&emsp;Sets where the fog reaches its maximum  
&emsp;Relative to render distance
 - **Cave Fog and Sky**
   - Cave Fog  
&emsp;Fog changes to a different color when you are underground
   - Cave Sky  
&emsp;Sky changes to a different color when you are underground
   - Cave Sky Height Threshold  
&emsp;Controls which world height is necessary for the sky color to change
   - Cave Fog *(RGB Color Picker)*  
&emsp;Color of fog inside of caves
 - **Sun and Moon**
   - Change Sun and Moon Size
   - Sun and Moon Size  
&emsp;Changes the size of sun and moon
   - Sun Angle  
&emsp;Tilts the rotation axis of sun and moon  
&emsp;Vanilla is 0
   - Opacity when raining  
&emsp;100% full visibility  
&emsp;0% fully hidden when raining
   - Hide under Horizon  
&emsp;Sun and moon start disappearing under the horizon
   - Transition Height  
&emsp;Lower: sun and moon appear lower  
&emsp;Higher: sun and moon appear higher
   - Transition  
&emsp;Lower: Longer transition  
&emsp;Higher: Shorter transition
 - **Stars**
   - Vanilla Star Brightness
   - Custom Stars
   - Size
   - Density
   - Coverage
   - Glow Radius
   - Glow Amount
   - Shooting Stars  
&emsp;**Only** works with "Custom Stars" enabled
   - Direction
   - Density
   - Speed
   - Trail Length
   - Trail Thickness
 - Custom Sky Color
 - **Sky Color Configuration**
   - Custom Sunset
   - Sky Sunset *(RGB Color Picker)*
   - Sky Day *(RGB Color Picker)*
   - Sky Day Rain *(RGB Color Picker)*
   - Night Sky Brightness
   - Sky Night *(RGB Color Picker)*
   - Sky Night Rain *(RGB Color Picker)*
 - Custom Fog Color
 - **Fog Color Configuration**
   - Fog Day *(RGB Color Picker)*
   - Fog Day Rain *(RGB Color Picker)*
   - Night Fog Brightness
   - Fog Night *(RGB Color Picker)*
   - Fog Night Rain *(RGB Color Picker)*
 - **End Sky**
   - End Sky Upper *(RGB Color Picker)*
   - End Sky Lower *(RGB Color Picker)*

### Lighting

 - Lightmap - *Simple, Default*  
&emsp;Default:  
&emsp;All Features  
&emsp;Simple:  
&emsp;Reduced features (only "Adaptive Blocklight Reduction" and "Minimum Light")
 - **Lightmap Settings**
   - Skylight AO  
&emsp;Specifies the amount of ambient occlusion on skylight
   - Blocklight AO  
&emsp;Specifies the amount of ambient occlusion on blocklight
   - Skylight Gamma  
&emsp;Higher = Darker  
&emsp;Lower = Brighter
   - Blocklight Gamma  
&emsp;Higher = Darker  
&emsp;Lower = Brighter
   - Minimum Light  
&emsp;Sets the minimum lightmap luminance  
&emsp;Prevents caves from being pitch black (unless you set it to zero that is)
   - Night Vision Minimum Light  
&emsp;Sets the minimum lightmap luminance when the night vision effect is applied
   - Terrain Shading  
&emsp;Vanilla-Style Terrain Shading  
&emsp;Useful when smooth lighting is disabled
 - **Lightmap Colors**
   - Adaptive Blocklight Reduction  
&emsp;Reduces blocklight when the sky is bright to avoid clipping  
&emsp;If the blocklight is too bright during daytime, increase this slider
   - Nether Ambient Brightness
   - **End Ambient Light**
     - End Ambient Brightness
     - End Ambient Saturation
   - Skylight Day *(RGB Color Picker)*
   - Skylight Night *(RGB Color Picker)*
   - Blocklight *(RGB Color Picker)*  
&emsp;Select blocklight color (torches, glowstone, etc.)  
&emsp;If "Complex Blocklight" is enabled, this color will **NOT** be used
   - Complex Blocklight  
&emsp;Allows you to select two colors for blocklight  
&emsp;One for dark parts, one for bright parts
   - Blend Curve  
&emsp;Higher: Emphasize "Bright" color  
&emsp;Lower: Emphasize "Dark" color  
&emsp;50 = linear transition
   - Complex Blocklight Dark *(RGB Color Picker)*
   - Complex Blocklight Bright *(RGB Color Picker)*
 - Colored Lights  
&emsp;Enabled colored lighting on blocks
 - **Colored Light Settings**
   - Vibrance
   - Accumulation Rejection - *Low, Default, High*  
&emsp;Sets how temporal history information is discarded  
&emsp;Higher corresponds to history being discarded more easily
   - Acc. Blend Factor  
&emsp;Sets how temporal history information is merged with new information  
&emsp;A lower value places less emphasis on history and will cause colors to update faster at the cost of more flicker
   - Flicker Reduction  
&emsp;Increase this slider if you experience frequent spots of color blinking into existence  
&emsp;Higher values will decrease the speed at which new color spreads and appears
   - Acc. Regeneration Speed  
&emsp;Sets how fast empty regions (with no color information) are filled up  
&emsp;A high value will cause colors to appear faster initially, but may introduce flicker in disoccluded regions
   - Sample LOD Bias  
&emsp;Controls the detail level at which colors are sampled  
&emsp;A higher value will make colors smoother but may cause small lights to be skipped  
&emsp;A lower value will sample at higher detail but will decrease smoothness and introduce flicker  
&emsp;The shader does its best to calculate the appropriate LOD itself
 - Directional Lightmaps
 - Directional Lightmap Strength
 - Normals - *Generated, Texture*
 - Normals Resolution Multiplier  
&emsp;Auto-Generated Normals may have a different resolution than your resource pack  
&emsp;This slider allows you to select a higher resolution for the normals  
&emsp;No performance impact
 - HDR Emissives
 - HDR Emissive Brightness

### Weather

 - Rain Detection - *Temperature, Color*  
&emsp;How the shader detects if rain is present  
&emsp;"Color" is generally the better option  
&emsp;Select "Temperature" if:  
&emsp;Rain does not receive rain effects  
&emsp;Things that are not rain receive rain effects
 - Rain Opacity
 - Rain Refraction - *OFF, Fast, Fancy*
 - Rain Refraction Strength
 - Angled Downfall
 - Angled Downfall Amount
 - Angled Downfall Rotation Speed
 - Rain Puddles
 - **Rain Puddle Color**
   - Rain Puddle *(RGB Color Picker)*
 - Rain Puddle Coverage
 - Rain Puddle Size
 - Rain Puddle Opacity
 - Rain Puddle Parallax
 - Parallax Refraction
 - Parallax Depth

### Waving Blocks

 - Waving Blocks
 - Waving Blocks Amount
 - Waving Blocks Speed
 - Waving Leaves
 - Waving Lilypads  
&emsp;Controlled by "Waving Liquids Amount" and "Waving Liquids Speed"
 - Waving Lanterns
 - Waving Fire
 - Waving Liquids  
&emsp;Water and Lava
 - Waving Liquids Amount
 - Waving Liquids Speed

### Camera and Color

 - FXAA  
&emsp;Enables Anti-Aliasing  
&emsp;Improves quality of edges
 - High Quality Upscaling  
&emsp;Switches to bicubic sampling  
&emsp;Internally enables FXAA  
&emsp;Can be useful with lower render quality settings
 - Contrast
 - Vibrance
 - Saturation
 - Brightness
 - Vignette - *OFF, Round, Square*  
&emsp;Darkens screen borders
 - Vignette Strength
 - LUT  
&emsp;Applies a custom color LUT to the image  
&emsp;**Only works for Optifine G8 and higher!**  
&emsp;How to add your luts:  
&emsp;Extract the .zip  
&emsp;Go to: shaders/lut  
&emsp;Put your LUT in this folder and name it "lut[number].png"  
&emsp;You can then select the file using the slider  
&emsp;Up to 6 luts can be loaded this way
 - Selected LUT  
&emsp;Default LUTs shipped with the shader are:  
&emsp;lut0.png: Neutral  
&emsp;lut1.png: Skyfall  
&emsp;lut2.png: A Summer Night's Adventure  
&emsp;lut3.png: Chrome  
&emsp;lut4.png: Admiral's Anime LUT  
&emsp;lut5.png: Green->Red Color swap (Infrared)
 - Use LOG Color
 - LUT Cell Size  
&emsp;Amount of cells on one side  
&emsp;Count the squares on the lut image along one side to figure this out

### Water

 - Underwater Fog Density
 - Depth Influence  
&emsp;Higher: Depth will have a strong influence on fog density  
&emsp;Lower: Depth will have a weak influence on fog density  
&emsp;Zero:  Depth will have no influence on fog density
 - Fog Brightness Influence  
&emsp;Higher: Underwater fog will be darker at night
 - Fog Brightness Influence  
&emsp;Higher: Underwater fog will get darker faster when you dive deeper

### Utilities and Effects

 - Blinking Ores
 - **Blinking Ores Settings**
   - Blink Brightness
   - Diamond
   - Ancient Debris
   - Iron
   - Gold
   - Copper
   - Redstone
   - Lapis Lazuli
   - Emerald
   - Coal
   - Nether Quartz
   - Nether Gold
 - Damage Effect
 - Damage Effect Redness
 - Damage Effect Displacement
 - Damage Effect Cell Size
 - Speed Effect  
&emsp;Adds streaks when moving fast
 - Speed Effect Strength
 - Speed Effect Streak Length

### Other

 - **Distant Horizons**
   - Fade Terrain  
&emsp;Smoothly fades out Minecraft terrain, reducing the transition between Distant Horizons' terrain and Minecraft's terrain
   - Discard DH Terrain
   - Terrain Discard Tolerance
   - Chunk Discard DH Transparents
   - Transparents Discard Tolerance
 - Dithering - *None, Smart, Full*  
&emsp;Removes Banding  
&emsp;Smart: Enables dithering in select programs  
&emsp;Full: Enables dithering in all programs
 - Time Mode - *Realtime, Worldtime, Framecount*  
&emsp;Sets which method the shader uses to determine the time  
&emsp;Time is used for driving animations, for example waving leaves and water  
&emsp;Realtime:  
&emsp;Uses the actual time  
&emsp;Worldtime:  
&emsp;Uses the ingame time  
&emsp;This can be useful for animation tools like replaymod  
&emsp;Framecount:  
&emsp;Uses the frame count based on a fixed framerate  
&emsp;This can be useful for animation tools like replaymod
 - Time Mode Framerate  
&emsp;Framerate used for calculating the time when "Time Mode: Framecount" is selected
 - Solid Block Outline
 - Line Thickness  
&emsp;Applies to all lines, for example block outline and hit boxes  
&emsp;**Only works from versions 1.17 and onwards**  
&emsp;**Doesn't work on Iris**
 - Block Outline Style - *Black, White, Rainbow, Custom Color*
 - **Custom Color Configuration**
   - Block Outline *(RGB Color Picker)*
 - Aggressive Optimization - *OFF, On, Unsafe*  
&emsp;Activates Optimizations that can break some visuals or might break in future versions of Minecraft