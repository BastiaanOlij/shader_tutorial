Shader tutorial video 2d/3d
===========================

Just dumping my ideas down for this. May or may not be useful. 

Introduction
------------

What are shaders? Explain regardless of 2d or 3d we render (i.e. draw) polygons, to be exact, we render triangles.
In 2D in most cases everything you see is made up of quads so we end up rendering two triangles. There are other things but quads are our bread and butter and in the end they are all variations of the same theme.
In 3D we render more complex shapes but all are brought back to rendering triangles on screen.
For now we stick with 3D

Shaders
-------
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

Our first shader
----------------
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

Our second shader
-----------------
Lets start looking at fragment shaders and for this we're going to start with a new scene. We are again going to add a rectangle but this time we use a ColorRect. We'll use the layout options to make this full screen.
Now we could use a TextureRect here too and that would remove a step from what we're about to do but that would mean I can't show that step and it's imported for more complex shaders.

Lets again add a ShaderMaterial to our rectangle and create a new shader.

```
shader_type canvas_item;

void fragment() {
  COLOR = vec4(1.0, 0.5, 0.2, 1.0);
}
```

This is the simplest fragment shader we can have, just like our vertex shader it is implemented as a function. We are assigning a single build in variable called COLOR and that determines what color our pixel is rendered at. Lighting will be applied afterwards which may make this a lighter or darker tint but as we don't have any lighting in our scene we get the color as is.
Colors are stored as vec4s, the components are respectively red, green, blue and alpha and each should be a value between 0 (dark) and 1 (light). The alpha determines the transparency of our fragment.

We don't want a single color here so lets add in some texture mapping and recreate the functionality of our TextureRect.
```
shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;

void fragment() {
  COLOR = texture(our_texture, UV);
}
```
Again we've defined a uniform allowing us to supply our shader with a value. The type we use is sampler2D which tells Godot that we want to use a texture.
The text after the semicolon is called a hint and is optional. This gives Godot a little bit more knowledge about the type of texture we want, whether it is used for colors or a normal map or something else.
We now need to assign our texture, we find our new uniform listed in our new material under the shader param group. We'll use our good old Godot icon again (maybe should find a nice tileable alternative).

And there we go, our texture is visible nicely stretched out. When you look at our color assignment you see a new function called called texture, it looks up the color within our texture at a specific location. 
The first parameter is our texture but our second is another build in variable called UV. UV is a vector that automatically interpolates from 0,0 in the top left corner to 1,1 in the bottom right corner of our rectangle.
Note that coordinates in our texture lookup always run from 0,0 and 1,1, they are not pixel coordinates on the texture but are normalised. This often trips up people but in many cases it makes life a lot easier.

Lets add a bit of tiling, we first have to change the import properties of our texture to allow it to repeat and then change our code to: 
```
shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;
uniform float tile_factor = 10.0;

void fragment() {
  COLOR = texture(our_texture, UV * tile_factor);
}
```
Now we have 10 godot faces horizontally, and 10 vertically. Again we've used a uniform here so we can change

But they do look a little flat. That is because our rectangle isn't as high as it is wide. Lets fix that:
```
shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;
uniform float tile_factor = 10.0;

void fragment() {
  vec2 adjusted_uv = UV * tile_factor;
  adjusted_uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
  
  COLOR = texture(our_texture, adjusted_uv);
}
```

Now in our preview in the editor this will still look wrong because our rectangle probably doesn't match our viewport size, but if you run the project you will see it is correct.
We've made two changes in our code. The first is that we've defined a local variable called adjusted_uv which we default to 10 times our UV value.
The second is that we multiply the Y of our new UV with the aspect ratio of the screen. This is another build in variable we have access to that gives us the size our our current screen. Well actually its the size of our viewport but they are usually synonimous.

Finally lets see if we can combine what we've learned in the vertex shader with using our sine and cosine function, with our new fragment shader:
```
shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;
uniform float tile_factor = 10.0;
uniform vec2 time_factor = vec2(2.0, 3.0);
uniform vec2 offset_factor = vec2(5.0, 2.0);
uniform vec2 amplitude = vec2(0.05, 0.05);

void fragment() {
  vec2 adjusted_uv = UV * tile_factor;
  adjusted_uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
  
  adjusted_uv.x += sin(TIME * time_factor.x + (adjusted_uv.x + adjusted_uv.y) * offset_factor.x) * amplitude.x;
  adjusted_uv.y += cos(TIME * time_factor.y + (adjusted_uv.x + adjusted_uv.y) * offset_factor.y) * amplitude.y;
  
  COLOR = texture(our_texture, adjusted_uv);
}
```

You could now add sliders to our UI just like with our previous example to play around with the values and see what they all do but as we've already shown that off, we'll move on.

What we're still missing is our lighting, now as we said before we aren't going to implement a lighting shader but the standard lighting shader still needs something extra for this to work.

Lets add a 2d light to our scene and use a very simple texture for our light, make sure to set the height property of the light.
You can see that it does someting with the light, to be very honest, I'm not sure what the default logic is doing here. (Need to investigate this further before recording our tutorial)

The full calculation for lighting especially with complex materials would take a video in itself to explain but at the root of all lighting techniques is a deceptively simple principle. The angle at which light hits the surface determines how brightly it is illuminated. If light hits the surface straight on, the direction of the light is perpendicular to the surface, then we illuminate the surface at maximum brightness. If the light travels parallel to the surface, or comes from behind the surface, then there is no illumination of the surface.
To check the angle at which the light hits the surface we need to know the normal of that surface. The normal of the surface is a vector that points away from the surface. Lighting by its nature is a 3D process not a 2D process, for lighting in a 2D game we're pretending our lights are a certain distance above the 2D surface and most of our normals will thus always point upwards.
We can use normal map textures with our 2D object to simulate texture in our material and have the light show this.

But for our effect, we're going to calculate a normal and for this we assign another output called NORMAL:
```
shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;
uniform float tile_factor = 10.0;
uniform vec2 time_factor = vec2(2.0, 3.0);
uniform vec2 offset_factor = vec2(5.0, 2.0);
uniform vec2 amplitude = vec2(0.05, 0.05);

void fragment() {
  vec2 adjusted_uv = UV * tile_factor;
  adjusted_uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
  
  vec2 offset = vec2(sin(TIME * time_factor.x + (adjusted_uv.x + adjusted_uv.y) * offset_factor.x) * amplitude.x, cos(TIME * time_factor.y + (adjusted_uv.x + adjusted_uv.y) * offset_factor.y) * amplitude.y);
  adjusted_uv.x += offset.x;
  adjusted_uv.y += offset.y;
  
  COLOR = texture(our_texture, adjusted_uv);
  
  vec3 tangent = normalize(vec3(amplitude.x, 0.0, -offset.x));
  vec3 bitangent = normalize(vec3(0.0, amplitude.y, -offset.y));
  
  NORMAL = normalize(cross(tangent, bitangent));
}
```
We've stored the offset that we're using to change the lookup in our texture into a variable so we can reuse it. It's a bit of a trick but we're using our offsets as a gradient, imagine our surface is actually a wave, we're creating two vectors that are flush with the surface of the wave, one in the X direction, one in the Y direction (Z in our case is up), also called the tangent and bitangent vectors of our surface. We have to normalise these vectors, this function will ensure the length of the vectors equal 1 which is incredibly important with many calculations.
Then we simply perform a function called the cross. This function does a nifty multiplication between the two vectors that gives you a new vector that is perpendicular to the plane the other two vectors are in, provided all vectors are unit vectors. And, tada, this is the normal of the surface of our water.

Making the jump to 3D
---------------------
to be continued....














