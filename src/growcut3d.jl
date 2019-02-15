"""
```
l = segment_image(Algorithm::GrowCut, feature_vector::AbstractArray, seeds::AbstractArray{Int, 3}, t1::Int=27, t2::Int=27; max_iter::Int=1000, converge_at::Int=1, rule::Tuple{Function, Function}=(colour_diff,find_maxC))
```
Same as [`segment_image`](@ref segment_image(::GrowCut, ::AbstractArray, ::AbstractArray{Int, 2}, ::Int, ::Int; ::Int, ::Int, ::Tuple{Function, Function}))
except runs on 3d images.

# Example

Create synthetic 3d image and segment:

```julia
using Images, PictureSegmentation

# Create image of cone with multiple colours
img=Array{RGB{Float64},3}(undef,100,100,100)
for i in CartesianIndices(img)
    if (i[1]-50)^2 + (i[2]-50)^2 < (i[3]/4)^2
        img[i]=RGB(i[3]/100,0,1-(i[3]/100))
    else
        img[i]=RGB(0,0,0)
    end
end

# Create seed array and select seed pixels
seeds=zeros(Int,axes(img))
set_seed_pixels(seeds, img)

# Segment image
l = segment_image(GrowCut(), img, seeds)

# Create new image from labels and display
img2 = convert_labels(l)
display_3d(img2)
```

See also: [`display_3d`](@ref display_3d(::AbstractArray{RGB{Float64}, 3}, ::Int, ::Bool))
and [`set_seed_pixels`](@ref set_seed_pixels(::Array{Int,3}, ::AbstractArray, ::Int; ::Bool).
"""
function segment_image(Algorithm::GrowCut, feature_vector::AbstractArray, seeds::AbstractArray{Int, 3}, t1::Int=27, t2::Int=27; max_iter::Int=1000, converge_at::Int=1, rule::Tuple{Function, Function}=(colour_differance,find_maximum))
    # initialize values
    calculate_adjusted_strength = rule[1]
    extra_function = rule[2]
    extras = extra_function(feature_vector)
    labels = copy(seeds)
    E = zeros(Int, axes(labels))
    θ = set_strength(labels)
    labelsₜ₊₁ = copy(seeds)
    Eₜ₊₁ = zeros(Int, axes(labels))
    θₜ₊₁ = set_strength(labels)
    regions = maximum(seeds)
    iter = 0
    count = length(labels)
    changed = Array{Tuple{UnitRange{Int},UnitRange{Int},UnitRange{Int}},1}(undef,1)
    changedₜ₊₁ = Array{Tuple{UnitRange{Int},UnitRange{Int},UnitRange{Int}},1}(undef,0)
    rₘ, cₘ, wₘ = size(labels)
    changed[1] = 1:rₘ, 1:cₘ, 1:wₘ

    # overflow warning
    if typeof(feature_vector) == Array{RGB, 3} && typeof(feature_vector) != Array{RGB{Float64}, 3}
        @warn "feature_vector is RGB and not of type RGB{Float64}. This may cause overflow errors."
    end

    # iterate till convergence or maximum iterations reached
    while count > converge_at && iter < max_iter
        iter += 1
        count = 0
        copyto!(θₜ₊₁, θ)
        copyto!(labelsₜ₊₁, labels)
        copyto!(Eₜ₊₁, E)

        # loop through active pixel neighbourhoods (all pixels on first iteration)
        for j in CartesianIndices(changed)
            @inbounds for i in CartesianIndices(changed[j])
                Nbound = max(i[1]-1,1):min(i[1]+1, rₘ), max(i[2]-1, 1):min(i[2]+1, cₘ), max(i[3]-1, 1):min(i[3]+1, wₘ)
                Eₜ₊₁[i] = count_enemy(labels, i, Nbound)
                if E[i] < t2
                    θₜ₊₁, labelsₜ₊₁, count, changedₜ₊₁ = update_pixel(θ, θₜ₊₁, labels, labelsₜ₊₁, feature_vector, E, i, extras, t1, count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
                else
                    θₜ₊₁, labelsₜ₊₁, count, changedₜ₊₁ = occupy_pixel(θ, θₜ₊₁, labels, labelsₜ₊₁, feature_vector, i, extras, count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
                end
            end
        end

        # update values
        # changed=changedₜ₊₁
        changedₜ₊₁ = similar(changedₜ₊₁, 0)
        E = Eₜ₊₁
        θ = θₜ₊₁
        labels = labelsₜ₊₁
    end
    return labels
end
