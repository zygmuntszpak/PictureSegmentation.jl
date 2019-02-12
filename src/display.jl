@doc raw"""
```
display_3d(img::Array{RGB, 3}, layer::Int=1, suppress_feedback::Bool=false)
```

Function for displaying 3d images in a user-freindly way using Makie.

# Arguments

The function arguments are described in more detail below.

##  `img`

An `AbstractArray` containing the 3d image to be viewed.

##  `layer`

An `Int` which controls the layer which is displayed initially. If not defined
then the first layer will be shown.

##  `suppress_feedback`

An `Bool` keyword argument which controls if console feedback is to be returned.

# Controls

Right mouse button: move image.
Scroll: zoom.
Left arrow: change layer up.
Right arrow: change layer down.

# Example

Create and view synthetic 3d image.
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

#display
display_3d(img)
```
"""
function display_3d(img::AbstractArray, layer::Int=1, suppress_feedback::Bool=false)
    scene = Scene()
    image!(scene,img[:,:,layer], show_axis = false)
    display(scene)
    #change layer
    on(scene.events.keyboardbuttons) do buttons
        if ispressed(scene, Keyboard.right)
            if layer != length(img[1,1,:])
                layer += 1
                image!(scene,img[:,:,layer], show_axis = false)
                display(scene)
                if suppress_feedback == false
                    println("layer: ", layer)
                end
            end
        end
        if ispressed(scene, Keyboard.left)
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
end


@doc raw"""
```
img = convert_labels(labels::Array{Int})
img = convert_labels(labels::Array{Int}, img::AbstractArray)
```

Converts a label array of type `Int` into a RGB image with each region having a
unique colour. If the original image is passed then the region will be assigned
the average colour of is pixels.

# Arguments

The function arguments are described in more detail below.

#  `labels`

An array of `Int` containing the assigned label for each pixel.

##  `img`

An `AbstractArray` containing the original image.
"""
function convert_labels(labels::Array{Int})
    img = zeros(RGB,axes(labels))
    regions=maximum(labels)
    for i in CartesianIndices(img)
        cVal = π*labels[i]/regions
        img[i] = RGB(sin(cVal)/2+0.5, sin(cVal+π/2)/2+0.5, sin(cVal-π/2)/2+0.5)
    end
    return img
end


function convert_labels(labels::Array{Int}, img::AbstractArray)
    img2 = zeros(RGB{Float64},axes(labels))
    regions = maximum(labels)
    colours = zeros(RGB{Float64},regions)
    counts = zeros(Int,regions)
    for i in CartesianIndices(img)
        if labels[i] != 0
            colours[labels[i]] = colours[labels[i]] + img[i]
            counts[labels[i]] += 1
        end
    end
    for i in eachindex(colours)
        colours[i] = colours[i]/counts[i]
    end
    for i in CartesianIndices(img2)
        if labels[i] != 0
            img2[i] = colours[labels[i]]
        else
            img2[i] = RGB(0.0, 0.0, 0.0)
        end
    end
    return img2
end

@doc raw"""
```
Contours = make_contour(label::Array{Int})
```

Creates a binary mask for the contours of the segmentation of an image using
an array of labels.

# Arguments

The function arguments are described in more detail below.

#  `labels`

An array of `Int` containing the assigned label for each pixel.
"""
function make_contour(label::Array{Int})
    contour_mask = zeros(Int, size(label))
    r, c = size(label)
    for i in CartesianIndices(label)
        rₘ, cₘ = i.I
        r₀ = max(rₘ-1, 1)
        r₁ = min(rₘ+1, r)
        c₀ = max(cₘ-1, 1)
        c₁ = min(cₘ+1, c)
        if label[i] != label[r₀, cₘ]
            contour_mask[i] = 1
        elseif label[i] != label[r₁, cₘ]
            contour_mask[i] = 1
        elseif label[i] != label[rₘ, c₀]
            contour_mask[i] = 1
        elseif label[i] != label[rₘ, c₁]
            contour_mask[i] = 1
        end
    end
    return contour_mask
end
