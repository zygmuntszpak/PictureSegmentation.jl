@doc raw"""
```
set_seed_pixels!(labels::Array{Int,2}, img::AbstractArray; suppress_feedback::Bool=false)
```

A mutating function so allow for interactive selection of seed pixels to be used
with segmentation algorithms. Mutates the labels variable to contain initial seeds.
Uses Makie to provide user interface.

# Details

The function allows for users to interactively select seed pixels and their regions.
This is achieved using mouse and keyboard interactions  described in more detail
bellow.

# Arguments

The function arguments are described in more detail below.

##  `labels`

An `Array{Int,2}` containing the labels to be assigned to each pixel. Should be
initialized as the same size as image and passed containing only zeros or other
seeds.

##  `img`

An `AbstractArray` containing the image to be seeded.

##  `suppress_feedback`

An `Bool` keyword argument which controls if console feedback is to be returned.

# Controls

Left mouse button: select seeds.
Right mouse button: move image.
Scroll: zoom.
Left arrow: change region down.
Right arrow: change region up.

# Example

Select seeds in the "toucan" image.

```julia
using Images, PictureSegmentation
img = testimage("toucan")

#convert to RGB{Float64}
img=RGB{Float64}.(img)

#create array of seeds in itilized to 0
seeds = zeros(Int,axes(img))

#use set_seed_pixels to set the inital seeds
set_seed_pixels(clicks, img)

#you can now seed the image as you wish
```
"""
function set_seed_pixels!(labels::Array{Int,2}, img::AbstractArray; suppress_feedback::Bool=false)
    #setup initial scene
    scene = Scene()
    image!(img, show_axis = false)
    clicks = Node(Point2f0[])
    region = 1
    #place seed
    on(events(scene).mousedrag) do buttons
        if ispressed(scene, Mouse.left)
            pos = to_world(scene, Point2(scene.events.mouseposition[]))
            position = (round(Int,(pos[1]/axes(img)[2][end])*axes(img)[1][end]),round(Int,(pos[2]/axes(img)[1][end])*axes(img)[2][end]))
            if minimum(position)>1 && position[1]<axes(img)[1][end]-1 && position[2]<axes(img)[2][end]-1
                push!(clicks, push!(clicks[], pos))
                labels[position[1],position[2]]=region
                if suppress_feedback == false
                    println("position, region: ", position, region)
                end
            end
        end
        return
    end
    #change region
    on(scene.events.keyboardbuttons) do buttons
        if ispressed(scene, Keyboard.right)
            region += 1
            if suppress_feedback == false
                println("region: ", region)
            end
        end
        if ispressed(scene, Keyboard.left)
            if region!=1
                region -= 1
                if suppress_feedback == false
                    println("region: ", region)
                end
            end
        end
        return
    end
    #display seeds
    scatter!(scene, clicks, color = :red, marker = '.', markersize = 3,show_axis = false)
end

@doc raw"""
```
set_seed_pixels!(labels::Array{Int,3}, img::AbstractArray, layer::Int = 1; suppress_feedback::Bool=false)
```

A mutating function so allow for interactive selection of seed pixels to be used
with segmentation algorithms. Mutates the labels variable to contain initial seeds.
Uses Makie to provide user interface.

# Details

The function allows for users to interactively select seed pixels and their regions.
This is achieved using mouse and keyboard interactions  described in more detail
bellow.

# Arguments

The function arguments are described in more detail below.

##  `labels`

An `Array{Int,3}` containing the labels to be assigned to each pixel. Should be
initialized as the same size as image and passed containing only zeros or other
seeds.

##  `img`

An `AbstractArray` containing the image to be seeded.

##  `layer`

An `Int` which controls the layer which is displayed initially. If not defined
then the first layer will be shown.

##  `suppress_feedback`

An `Bool` keyword argument which controls if console feedback is to be returned.

# Controls

Left mouse button: select seeds.
Right mouse button: move image.
Scroll: zoom.
Left arrow: change region down.
Right arrow: change region up.
Up arrow: change layer up.
Down arrow: change layer down.

# Example

Select seeds in synthetic 3d image.

```julia
using Images, PictureSegmentation

#create image of cone with multiple colours
img=Array{RGB{Float64},3}(undef,100,100,100)
for i in CartesianIndices(img)
    if (i[1]-50)^2 + (i[2]-50)^2 < (i[3]/4)^2
        img[i]=RGB(i[3]/100,0,1-(i[3]/100))
    else
        img[i]=RGB(0,0,0)
    end
end

#create array of seeds in itilized to 0
seeds = zeros(Int,axes(img))

#use set_seed_pixels to set the inital seeds
set_seed_pixels(clicks, img)

#you can now seed the image as you wish
```
"""
function set_seed_pixels!(labels::Array{Int,3}, img::AbstractArray, layer::Int = 1; suppress_feedback::Bool=false)
    #setup scene
    scene = Scene()
    clicks = Node(Point2f0[])
    region = 1
    image!(scene,img[:,:,layer], show_axis = false)
    #set seed
    on(events(scene).mousedrag) do buttons
        if ispressed(scene, Mouse.left)
            pos = to_world(scene, Point2(scene.events.mouseposition[]))
            position = (round(Int,(pos[1]/axes(img)[2][end])*axes(img)[1][end]),round(Int,(pos[2]/axes(img)[1][end])*axes(img)[2][end]))
            if minimum(position)>1 && position[1]<axes(img)[1][end]-1 && position[2]<axes(img)[2][end]-1
                push!(clicks, push!(clicks[], pos))
                labels[position[1],position[2],layer]=region
                if suppress_feedback == false
                    println("position, layer, region: ", position, layer, region)
                end
            end
        end
        return
    end
    #change layer and region
    on(scene.events.keyboardbuttons) do buttons
        if ispressed(scene, Keyboard.right)
            region += 1
            if suppress_feedback == false
                println("region: ", region)
            end
        end
        if ispressed(scene, Keyboard.left)
            if region!=1
                region -= 1
                if suppress_feedback == false
                    println("region: ", region)
                end
            end
        end
        if ispressed(scene, Keyboard.up)
            if layer != length(img[1,1,:])
                layer += 1
                image!(scene,img[:,:,layer], show_axis = false)
                display(scene)
                if suppress_feedback == false
                    println("layer: ", layer)
                end
            end
        end
        if ispressed(scene, Keyboard.down)
            if layer != 1
                layer -= 1
                image!(scene,img[:,:,layer], show_axis = false)
                display(scene)
                if suppress_feedback == false
                    println("layer: ", layer)
                end
            end
        end
        return
    end
    scatter!(scene, clicks, color = :red, marker = '.', markersize = 3,show_axis = false)
end
