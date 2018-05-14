# Shader tutorial video 2d/3d

Just dumping my ideas down for this. May or may not be useful. The idea was to do a shader co-op tutorial first explaining how 2d shaders work, and then apply similar techniques for a 3d shader. We've decided to look into distortion shaders as these are fairly simple and good beginner shaders.

The plan is for you to do the 2d shader video, I will do the 3d shader video. I however have taken the liberty to do my take on the full shader tutorial mainly just to get my ideas down on paper but also so we just have a start. Feel free to use whatever you think you can use and ignore whatever it is you would do a different take on.

## Introduction

First part of the introduction, I'll leave up to you to fill in, welcome to this coop tutorial, this is the first part and we'll focus on 2d shaders, the second part will be by Bastiaan Olij and focus on the 3d counter parts of these shaders, yada yada yada...

What are shaders? Explain regardless of 2d or 3d we render (i.e. draw) polygons, to be exact, we render triangles.
In 2D in most cases everything you see is made up of quads so we end up rendering two triangles. There are other things but quads are our bread and butter and in the end they are all variations of the same theme.
In 3D we render more complex shapes but all are brought back to rendering triangles on screen.
For now we stick with 2D

*Note* Before we begin, all textures must be set to being repeatable textures! Edit the import settings for this, maybe also highlight this in the video. 

## 2D Shaders
Shaders are small programs running on your graphics card that do the actual work involved in drawing these triangles.
The parts that are exposed to you, the programmer, are only smaller parts of the shader program. Most of the logic is performed by the hardware and it calls your logic to fill in the blanks.
Traditionally we deal with two shaders the hardware requires us to implement namely the vertex shader and the fragment shader.

The code in the vertex shader is run for every vertex of the polygon you want to render to screen. If you are rendering a quad it is called four times. The vertex shader is responsible for determining the location on screen where that vertex will be placed.
The hardware then renders the triangles using those end points.
For each pixel within those triangles the fragment shader is run. It is responsible for determining the color that is ultimately output to screen.

In Godot however we have split the part of the fragment shader that determines how the pixel is lit into a separate shader called the lighting shader.
In Godot the fragment shader is responsible for determining the base color of the pixel along with a few other properties, say blue.
The lighting shader is then run for each light that illuminates our pixel to determine how bright that pixel needs to be, say dark blue because its in shadow, or very light blue because a spotlight shines on it.

Writing your own lighting shader is an advanced topic and we won't be covering it in these videos. The default logic Godot executes will suffice in nearly all scenarios. It is only when you want to do things like cartoon shaders that writing your own lighting shader becomes important.

## Our first shader
Lets start with doing a little bit of setup, we add a TextureRect to our screen and we assign a texture to our TextureRect. We'll assign our Godot icon to this for now.
Our rectangle is already being rendered by a shader but it is using Godots build in shader. This is already a very capable shader that will do many things for you. You have more customisation options with this shader by creating a CanvasItemMaterial and using that for our rectangle and just playing around with the settings that offers you.

But there comes a time that you'll want to do something unique and you will need to write your own shader logic and we do this by creating a ShaderMaterial for our rectangle, and then creating a new shader for that material.

When you create a new shader in Godot you actually start with a fully functional shader with all three parts implemented and here lies an important fact that sets Godot apart.
Many other game engines will provide a default vertex and fragment shader but the moment you start implementing your own you'll loose much of the default logic.

Godot will try to keep doing its default logic until you write something that replaces it. 

In Godot 2, Godot had its own GLSL inspired shader language. In Godot 3 we are using GLSL syntax for our shaders but there are a few differences. 
The main important difference is that we write the 3 parts of our shader, or atleast the parts we chose to implement, in a single file so they are named differently. The other difference is that Godot has its own build in variables that we will be manipulating. But other then that you are writing a GLSL shader and that means that many of the online resources that show you how to write GLSL shaders will help you writing Godot shaders.

The first thing we need to do, and Godot already informs us of this, is tell Godot the type of shader we are writing. As we are creating a 2D shader, we need to create a canvas_item shader.
Note that Godot is constantly recompiling our shader as we make changes and it will show us any errors we make. Once the shader is successfully compiled we will immediately see the end result.

In many cases there isn't a need to implement a vertex shader in 2D but we'll do a very quick demo of what we can do here.

```
shader_type canvas_item;

void vertex() {
  VERTEX.x += sin(TIME * 2.0) * 10.0;
  VERTEX.y += cos(TIME * 2.0) * 10.0;
}
```

We're going to add a sine value to the x of our vertex and a cosine value to our y and suddenly our image starts to move around. We now have a few bits that are important. First is that the vertex shader is implemented as a function called vertex. The variable VERTEX is a build in variable which is a Vector2 containing the position of our vertex and we can modify it.
The other variable we are using is TIME which is an input variable that tells us how many seconds have passed since Godot was started. By using that as the input of our sine and cosine functions we drive the animation.

But right now we're applying the same change to all four vertices. Remember our vertex function is called for each corner of our rectangle but it just does the same thing 4 times. We could create the same effect by simply changing the position of our rectangle in GDScript.

```
shader_type canvas_item;

void vertex() {
  VERTEX.x += sin(TIME * 2.0 + VERTEX.x + VERTEX.y) * 10.0;
  VERTEX.y += cos(TIME * 2.0 + VERTEX.x + VERTEX.y) * 10.0;
}
```

By offsetting our sine and cosine function by values related to each individual vertex 
While not a very useful implementation it does show how easy it is to manipulate the vertices of our rectangle and end up with a dancing Godot.
Finally on the subject of vertex shaders, the output position is still is "world" space, not the coordinates on screen. Those will be determined by Godot later on. You can override that behaviour but that is something for an advanced tutorial.

The final thing we'll do is make it possible to change the speed and amplitude of our animation from outside of our shader:
```
shader_type canvas_item;

uniform vec2 time_factor = vec2(2.0, 2.0);
uniform vec2 amplitude = vec2(10.0, 10.0);

void vertex() {
  VERTEX.x += sin(TIME * time_factor.x + VERTEX.x + VERTEX.y) * amplitude.x;
  VERTEX.y += cos(TIME * time_factor.y + VERTEX.x + VERTEX.y) * amplitude.y;
}
```

Instead of having fixed numbers we now use 2d vectors for our timing and out amplitude. You could make these floats but making them a 2d vector allows you to easily set these separately for the x and y axis.
Note the word "uniform" that preceeds the variable definition. You can think of uniforms as the same sort of thing as export variables in GDScript. They let you change these values from outside the shader however inside of the shader they are considered constants (show shader params panel on the TextureRects material).

Let's add a slider to our UI with which to change the amplitude of our animation. We also add a script to the root node and hook up the sliders value changed signal.
```
extends Node

onready var material = $TextureRect.material
var amplitude

func _ready():
  # initialise our starting value, note that this can be null if you haven't specified defaults on your material.
  amplitude = material.get_shader_param("amplitude")
  if !amplitude:
    amplitude = Vector2(10.0, 10.0)
  $Amplitude_X.value = amplitude.x

func _on_Amplitude_X_value_changed(value):
  amplitude.x = value
  material.set_shader_param("amplitude", amplitude)
```

In our ready function we'll get our starting value and populate our sliders value. Note that we can get a null value here when the defaults have not been changed.
On our sliders signal we change the x component of our variable and assign our shader parameter. 

See if you can add sliders for the other 3 variables.

## Our second shader
Lets start looking at fragment shaders and for this we're going to start with a new scene. We are again going to add a rectangle but this time we use a Sprite just to show another option for this.

Lets again add a ShaderMaterial to our Sprite and create a new shader, exactly the same as before.

```
shader_type canvas_item;

void fragment() {
  COLOR = vec4(1.0, 0.5, 0.2, 1.0);
}
```

This is the simplest fragment shader we can have, just like our vertex shader it is implemented as a function. We are assigning a single build in variable called COLOR and that determines what color our pixel is rendered at. Lighting will be applied afterwards which may make this a lighter or darker tint but as we don't have any lighting in our scene we get the color as is.
Colors are stored as vec4s, the components are respectively red, green, blue and alpha and each should be a value between 0 (dark) and 1 (light). The alpha determines the transparency of our fragment.

We don't want a single color here so we are going to apply a texture, note that the change we're making to our fragment shader makes it work exactly like the build in one..
```
shader_type canvas_item;

void fragment() {
  COLOR = texture(TEXTURE, UV);
}
```
We now need to assign our texture. We'll use our good old Godot icon again.

We're introduced to 3 new things here.
The first is the function texture, note the lower case, which does a lookup for a pixel in our texture.
The second is the build in variable TEXTURE, note the upper case, which is the texture assigned to our sprite.
The third is a build in variable UV, again note the upper case, which gives us our default texture coordinate for this fragment.

The UV is automatically interpolated from 0,0 in the top left corner to 1,1 in the bottom right corner of our sprite.
Note that coordinates in our texture lookup always run from 0,0 and 1,1, they are not pixel coordinates on the texture but are normalised. This often trips up people but in many cases it makes life a lot easier.

Lets add a bit of tiling, we first have to change the import properties of our texture to allow it to repeat and then change our code to: 
```
shader_type canvas_item;

uniform float tile_factor = 10.0;

void fragment() {
  COLOR = texture(TEXTURE, UV * tile_factor);
}
```
Now we have 10 godot faces horizontally, and 10 vertically. We're again using a uniform here so we can change the value from GDScript.

But they do look a little squished. That is because our rectangle isn't as high as it is wide. Lets fix that:
```
shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

void fragment() {
  vec2 adjusted_uv = UV * tile_factor;
  adjusted_uv.y *= aspect_ratio;
  
  COLOR = texture(TEXTURE, adjusted_uv);
}
```

Unfortunately we do not know the size of our rectangle nor that of our texture inside of our shader. This is not exposed through build in variables. What we need to know to correctly size our tiles is the aspect ratio of our texture. We'll need to calculate this in GDScript so we declare this as a uniform variable.

We've also defined a local variable called adjusted_uv which we default to 10 times our UV value.
Then we multiply the Y of our new UV with the aspect ratio. 

Now all we need to do is set our aspect ratio to the correct value so we add a GDScript to our Sprite node and add the following code:
```
func _ready():
  material.set_shader_param("aspect_ratio", scale.y/scale.x)
```
Because of the way Sprites work in Godot the size of our rectangle is always a multiple of the size of the texture we use and that multiple is defined by the scale. Therefor our aspect ratio is simply the y of our scale divided by the x of our scale.

One thing that is important to remember is that we set our uniform on our material and it is therefor applied to any object on screen that shares the same material. If you want to reuse the same shader on various objects that all need to have different values for the shader parameters, make sure to create a new material on that object and assign the same shader to that material.

Finally lets see if we can combine what we've learned in the vertex shader with using our sine and cosine function, with our new fragment shader:
```
shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

uniform vec2 time_factor = vec2(2.0, 3.0);
uniform vec2 offset_factor = vec2(5.0, 2.0);
uniform vec2 amplitude = vec2(0.05, 0.05);

void fragment() {
  vec2 adjusted_uv = UV * tile_factor;
  adjusted_uv.y *= aspect_ratio;
  
  adjusted_uv.x += sin(TIME * time_factor.x + (adjusted_uv.x + adjusted_uv.y) * offset_factor.x) * amplitude.x;
  adjusted_uv.y += cos(TIME * time_factor.y + (adjusted_uv.x + adjusted_uv.y) * offset_factor.y) * amplitude.y;
  
  COLOR = texture(TEXTURE, adjusted_uv);
}
```

You could now add sliders to our UI just like with our previous example to play around with the values and see what they all do but as we've already shown that off, we'll move on.

### Changing over to a DuDv map
Using sine and cosines for our distortion is all well and good but especially over larger areas it can become pretty repetative. You can always add different octaves of sines with different offsets to create some more interesting ripples. What we'll do here however is use a special texture map called a DuDv map, or delta U, delta V map. This is a texture map where the red and green color channels hold an offset for our UV.

Let's see what our fragment shader looks like now:
```
shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

uniform sampler2D DuDvMap : hint_black;
uniform vec2 time_factor = vec2(0.05, 0.08);
uniform vec2 DuDvFactor = vec2(0.2, 0.2);
uniform float DuDvAmplitude = 0.1;

void fragment() {
  vec2 DuDv_UV = UV * DuDvFactor; // Determine the UV that we use to look up our DuDv
  DuDv_UV += TIME * time_factor; // add some animation
  
  vec2 offset = texture(DuDvMap, DuDv_UV).rg; // Get our offset
  offset = offset * 2.0 - 1.0; // Convert from 0.0 <=> 1.0 to -1.0 <=> 1.0
  offset *= DuDvAmplitude; // And apply our amplitude
  
  vec2 adjusted_uv = UV * tile_factor; // Determine the UV for our texture lookup
  adjusted_uv.y *= aspect_ratio; // Apply aspect ratio
  adjusted_uv += offset; // Distort using our DuDv offset
  
  COLOR = texture(TEXTURE, adjusted_uv); // And lookup our color
}
```
The one thing we've not done before is using a uniform to allow us to use a second texture in our shader. The line that lets us do this is ```uniform sampler2D DuDvMap : hint_black```.
As before this is defined as a uniform so we can set it outside of our shaders.
It is declared as a sampler2D which basically translates to, this is a texture.
We've given it a name, DuDvMap.
And finally we have something new, we've given it a hint. This tells Godot something about the texture. In our case we give it a *hint_black* which roughly translates to us wanting the color black if no texture is given.

We now need to go to our material properties and assign a texture to our new DuDvMap and as soon as we do, we see a far nicer water ripple distortion then our sines gave.

But how does this work? Well at the top we start by calculating the UV with which we want to look up an entry in the DuDvMap. We multiply this by a factor and as our DuDv map is a bit larger then our Sprite we're scaling it down.
We then add our TIME offset to animate our water and again we multiply this by a factor which effects the speed of our animation.

Now we can load the value from our DuDvMap but we only need the red and green colors, hence the .rg we've added to our texture lookup.
Our red and green values will be a value between 0 and 1, but we want a value between -1 and 1. The times 2 minus 1 calculation is one you will often see in shaders as this is a very common conversion.

Finally we multiply our offset by an amplitude as we only want to offset our value slightly.
Instead of adding our sine and cosine values we replace that code by simply adding the offset.

And that is all.

### Perfecting the lighting
What we're still missing is our lighting, now as we said before we aren't going to implement a lighting shader but the standard lighting shader still needs something extra for this to work.

Lets add a 2d light to our scene and use a very simple texture for our light, make sure to set the height property of the light.
The light just illuminates our Sprite asif it is a flat rectangle. It has no idea that we are distorting the texture to create the illusion of ripples in the water. We need to tell it that our rectangle is no longer flat.

The full calculation for lighting especially with complex materials would take a video in itself to explain but at the root of all lighting techniques is a deceptively simple principle. The angle at which light hits the surface determines how brightly it is illuminated. If light hits the surface straight on, the direction of the light is perpendicular to the surface, then we illuminate the surface at maximum brightness. If the light travels parallel to the surface, or comes from behind the surface, then there is no illumination of the surface.

We thus need to inform our lighting shader of the orientation of our fragment and we do this by supplying it with the normal vector of our fragment. A normal vector is a vector that points straight out of our surface.

We can calculate our normal vector from our DuDv map but lucky for us this has already been done and the result stored in a normal map. A normal map is simply a texture that stores normal vectors for a surface.

Normal maps are widely used to add texture to our textures and we can see that our Sprite has support for normal maps so we start by assigning our normal map to our normal map property.

Now we can see that our normal map has indeed had an effect on our lighting, just not the effect we were hoping for. The normal map Godot was expecting was one that matched our Godot texture but we're using it very differently. Luckily a very simple change to our fragment shader can rectify the problem.

```
shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

uniform sampler2D DuDvMap : hint_black;
uniform vec2 time_factor = vec2(0.05, 0.08);
uniform vec2 DuDvFactor = vec2(0.2, 0.2);
uniform float DuDvAmplitude = 0.1;

void fragment() {
  vec2 DuDv_UV = UV * DuDvFactor; // Determine the UV that we use to look up our DuDv
  DuDv_UV += TIME * time_factor; // add some animation
  
  vec2 offset = texture(DuDvMap, DuDv_UV).rg; // Get our offset
  offset = offset * 2.0 - 1.0; // Convert from 0.0 <=> 1.0 to -1.0 <=> 1.0
  offset *= DuDvAmplitude; // And apply our amplitude
  
  vec2 adjusted_uv = UV * tile_factor; // Determine the UV for our texture lookup
  adjusted_uv.y *= aspect_ratio; // Apply aspect ratio
  adjusted_uv += offset; // Distort using our DuDv offset
  
  COLOR = texture(TEXTURE, adjusted_uv); // And lookup our color
  NORMALMAP = texture(NORMAL_TEXTURE, DuDv_UV).rgb;
}
```

We just needed to add one line where we lookup the value in from NORMAL_TEXTURE using the same UV as our DuDvMap lookup, and assign that to a special build in output called NORMALMAP.
Now the effect is a little hard to see because our texture is already relatively bright but if you comment out the COLOR line and replace is with:
```
COLOR = vec4(0.3, 0.3, 0.3, 1.0);
```
Using a single color for our output really shows how the light gets rippled in sync with our distortion.











