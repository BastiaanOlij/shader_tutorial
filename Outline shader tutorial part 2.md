# Making the jump to 3D

Ok, so this will be my part I guess, I'm making the assumption that what I covered above, will be covered in your video in one way, shape or form and that I can build on that.

I'm doing the same thing here as with the 2D part, just jotting down my initial ideas of what to present, and then we'll tweak and refine it.

## Introduction

Welcome everyone to part two of our Godot Shader beginners tutorial. I'm doing a colab with Nathan from GDQuest who has recorded part one of this tutorial covering 2D shaders. If you haven't seen that tutorial already shoot on down to the link below and watch that first. I will make the assumption that you have seen his video and will not repeat some of the concepts he discusses. 

Nathan has gone through creating a 2D shader step by step. At the end he had a nice 2D animated water effect. We'll be looking at creating a similar shader but in 3D. For a larger body of water you can obtain amazing results with the standard SpatialMaterial by just using a normal map. But we're going to have a look at something a little more close up so we can demonstrate some cool concepts.

## Starting with a vertex shader
*for each step I'll create an inherited scene of our base, they are in the water_3d folder. We start with the displacement example*

For 2D it is a little easier to demonstrate a shader effect without dressing up the scene, for 3D it is always nice to have an environment for our material to interact with, especially one that will end up being transparent.

So I have created a very simple pool scene consisting of just a few textures planes. I've also loaded up an HDRI skymap. We won't get any benefits of that until the end of the tutorial though.

We start by adding a new MeshInstance node and create a PlaneMesh. We're going to make this the size of our pool and then we subdivide the mesh so we have some vertices to work with.

Now we need to add a material. For our purposes today it doesn't matter whether we create the material on the Mesh or the MeshInstance. I'll add it to the MeshInstance, select ShaderMaterial from the dropdown and click on the material to edit it.
We'll save our material as a resource, this makes it easier to access it or reuse it later.
Now we'll create a Shader for our ShaderMaterial.

Our 3D shaders have a lot in common with our 2D shaders. We need to define the shader type at the top of our shader script but in this case we define it as a Spatial shader.
Just like our 2D shaders we can add a vertex function, fragment function and a lighting function and they have the same purpose.

For our first step we are purely going to look at the vertex function:
```
shader_type spatial;

void vertex() {
	VERTEX.y += sin(VERTEX.x);
}
```
The vertex shader is executed for every vertex in our mesh. If we hadn't subdivided our plane we would only have 4 vertices to play with and we would still end up with a flat plane, just one that is skewed strangely. By subdividing our plane we get a nice sine shape.

VERTEX is a build in variable that gives us access to the position vector of the vertex we're currently processing. This is the position before our mesh is placed into the world. After our vertex function is finished Godot will apply the transformation needed to place the vertex in the right location on screen. We have access to that transformation, but we'll leave that for an advanced shader tutorial.

We are purely updating the y component of our vector and that results in the vertex moving either up or down. Do note that as we're updating the location before our mesh is placed within the world, this will only result in the vertex moving up or down on screen if you haven't changed the orientation of the mesh. 

We are using the x component as the input of our sine function. Based on the size of our plane the x value will range from -4 to 4 giving us just slightly more then one wave. Let's make this slightly more interesting by also using the z component and changing the frequency and amplitude:
```
shader_type spatial;

uniform vec2 amplitude = vec2(0.2, 0.1);
uniform vec2 frequency = vec2(3.0, 2.5);

void vertex() {
	VERTEX.y += (amplitude.x * sin(VERTEX.x * frequency.x)) + (amplitude.y * sin(VERTEX.z * frequency.y));
}
```

*should draw a diagram of how we're calculating the tangent and binormal of our water surface*
Now that looks slightly more interesting however our plane is all a uniform color.. 
The problem we are having is that we're not adjusting the normals of the surface of our water.
In order to do this we need to calculate two helper vectors:
- The tangent, or the vector that lies flat with the surface of the water on the z axis
- The binormal, also often refered to as the bitangent, or the vector that lies flat with the surface of the water on the x axis
We can then take the cross product of these two vectors to get our normal. Taking the cross product of two vectors that both have a length of 1, a unit vector, gives us a vector that is perpendicular to these two vectors. Exactly what we need.
As a bonus, Godot actually needs the tangent and binormal if you wish to apply a normal map to get more detail, which we'll do later on in our tutorial.

Because we need to sample the height of our water in various locations to make this logic work, we're going to show that just like in GDScript, you can create your own functions in a shader!

```
shader_type spatial;

uniform vec2 amplitude = vec2(0.2, 0.1);
uniform vec2 frequency = vec2(3.0, 2.5);

float height(vec2 pos) {
	return (amplitude.x * sin(pos.x * frequency.x)) + (amplitude.y * sin(pos.y * frequency.y));
}

void vertex() {
	VERTEX.y += height(VERTEX.xz); // sample the height at the location of our vertex
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2)) - height(VERTEX.xz + vec2(0.0, -0.2)), 0.4));
	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0)) - height(VERTEX.xz + vec2(-0.2, 0.0)), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}
```

Now I realise that calculating the normal is bordering on an advanced topic but you really can't avoid updating the normal when you change the position of the vertex. The approach I show here works well for any scenario where the new position can be calculated in a function.
Don't dispair however, while we're showing how the vertex shader works, there are many shader effects where you don't need to modify the vertices at all.

As Nathan showed we can access the time that has passed using the build in variable TIME.
It is however important to realise that this variable is only accessible from within our 3 shader functions.
For our height function we will have to pass it as a variable.
Only uniforms are globally accesible.

```
shader_type spatial;

uniform vec2 amplitude = vec2(0.2, 0.1);
uniform vec2 frequency = vec2(3.0, 2.5);
uniform vec2 time_factor = vec2(2.0, 3.0);

float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x * frequency.x + time * time_factor.x)) + (amplitude.y * sin(pos.y * frequency.y + time * time_factor.y));
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME); // sample the height at the location of our vertex
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME ), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}
```

## Adding a fragment shader
Just like in our 2d shader our water does look very repetative. Now we could do some more in the vertex shader but I think this is a good time to start looking at our fragment shader and see how much we can improve the way our water looks.
Also if you're following along I would try the next steps both with, and without, our vertex shader.

Now unlike our 2D shaders we don't have a way to use default textures and normal maps in our spatial shader. We will always need to define our own uniforms for our texture inputs.

We'll start with just simply texturing our water.

```
shader_type spatial;

uniform vec2 amplitude = vec2(0.2, 0.1);
uniform vec2 frequency = vec2(3.0, 2.5);
uniform vec2 time_factor = vec2(2.0, 3.0);

uniform sampler2D texturemap : hint_albedo;
uniform vec2 texture_scale = vec2(8.0, 4.0);

float height(vec2 pos, float time) {
	return (amplitude.x * sin(pos.x * frequency.x + time * time_factor.x)) + (amplitude.y * sin(pos.y * frequency.y + time * time_factor.y));
}

void vertex() {
	VERTEX.y += height(VERTEX.xz, TIME); // sample the height at the location of our vertex
	TANGENT = normalize(vec3(0.0, height(VERTEX.xz + vec2(0.0, 0.2), TIME) - height(VERTEX.xz + vec2(0.0, -0.2), TIME), 0.4));
	BINORMAL = normalize(vec3(0.4, height(VERTEX.xz + vec2(0.2, 0.0), TIME) - height(VERTEX.xz + vec2(-0.2, 0.0), TIME ), 0.0));
	NORMAL = cross(TANGENT, BINORMAL);
}

void fragment() {
	ALBEDO = texture(texturemap, UV * texture_scale).rgb;
}
```

Just like in our 2D shader we have access to a build in variable called UV however in our fragment shader we're assigning the color to a new output called ALBEDO and this color does not have an alpha. We'll get back to that last bit later.
Our fragment shader has outputs for all the variables that drive our PBR shader, so our metallic, roughness, rim, clearcoat, subsurface scatering, you name it.

Just to show how this works we'll add to of them:
```
void fragment() {
	ALBEDO = texture(texturemap, UV * texture_scale).rgb;
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
}
```
You can play around with these values a bit to get some silly looking reflections.

Now our water is opaque. Not really how water is supposed to be so it's time to add a little bit of transparency and this is where you need to be a bit careful.
Setting transparency is done by setting the ALPHA output in your fragment function. As soon as you assign the ALPHA output Godot starts treating your material as a transparent material and this has consequences. Transparent materials are always rendered last because in order for them to work, the underlying opaque material needs to be rendere first. Also transparent materials that overlap can come out looking weird.

Instead of just setting our alpha to a single value we're going to add a tiny bit of logic to make the white in our texture a little less transparent then the blue:
```
void fragment() {
	ALBEDO = texture(texturemap, UV * texture_scale).rgb;
	if (ALBEDO.r > 0.9 && ALBEDO.g > 0.9 && ALBEDO.b > 0.9) {
		ALPHA = 0.9;
	} else {
		ALPHA = 0.5;
	}
	METALLIC = 0.5;
	ROUGHNESS = 0.2;
}
```

Now it's time to make our water look a little less repetative.
*to be continued*


