@doc raw"""
```
l = segment_image(Algorithm::GrowCut, feature_vector::AbstractArray, seeds::AbstractArray{Int, 2}, t1::Int=9, t2::Int=9; max_iter::Int=1000, converge_at::Int=1, rule::Tuple{Function, Function}=(colour_diff,find_maxC))
```

Using a provided `feature_vector` (default rule uses RGB image) and an array of
seeds, `GrowCut` will use Cellular Automata to segment a image into different
regions. The algorithm takes two thresholds which can be used to control the
smoothness of the segmentation.

# Output

Returns a Array of Integers `l` that specifies the label assigned to each pixel.

# Details

The algorithm uses Cellular Automata to iteratively  apply a rule to each pixel
which then competes with its neighbours to label the pixel. By default the
algorithm takes an RGB image for the `feature_vector` however a custom rule can
be defined for other `feature_vector` types. To improve performance after the
first iteration only the neighbourhood surrounding a pixel that changed in the
previous iteration is checked.

# Arguments

The function arguments are described in more detail below.

##  `feature_vector`

An `AbstractArray` containing the feature vector for each pixel. The default rule
assumes this is an RGB value for the pixel. Note: RGB images should be converted
to RGB{Float64} to prevent overflow.

##  `seeds`

An `Array{Int, 2}` specifying initial labels. Any pixel that is a seed should be
set to the desired integer label and all other positions should be 0. This can
be generated using `set_seed_pixels`

## `t1` and `t2`

`Int`s that specifies the thresholds to be used for smoothing. `t1` is the maximum
number of "enemies" that a pixel can be surrounded by and still attack other
pixels. `t2` is the maximum number of "enemies" before the pixel is forced to
become the weakest enemy pixel. Note: these values can produce scenarios where
the algorithm is unable to converge and will instead reach its maximum number of
iterations.

## `maxiter`

An `Int` that specifies the maximum number of iterations before execution is
aborted. If left unspecified a default value of 1000 is used. This should never
be reached under normal conditions.

## `converge_at`

An `Int` that specifies the minimum number of changes across the image for
convergence. If left unspecified a default value of 1 is used.

## `rule`

A `Tuple{Function, Function}` that specifies the rule to be used for the
function. The first element is the rule that determines the strength of the
attacking pixel and the second element is used to calculate any extra
information needed by the rule. By default `colour_diff` and `find_maxC` are used. A
template for custom rules can be found using `help_rule_template` or generated into
a new file using `create_rule`.

# Example

Segment the "toucan" image using `GrowCut`

```julia
using Images, PictureSegmentation
img = testimage("toucan")

#convert to RGB{Float64}
img=RGB{Float64}.(img)

#create array of seeds in initialized to 0
seeds = zeros(Int,axes(img))

#use set_seed_pixels to set the inital seeds
set_seed_pixels(clicks, img, suppress_feedback=false)

#segment the image
l=segment_image(GrowCut(),img,clicks,9,9)

#create and display segmented image from labels
img2 = convert_labels(l)
img2
```

# Advanced

By default GrowCut uses the rule:

```math
\begin{aligned}
\textbf{for } \forall p &  \in  P                               &\\
                        & l_p^{t+1} =  l_p^{t}                  &\\
                        & \theta_p^{t+1} =  \theta_p^{t}        &\\
                        & \textbf{for } \forall q  \in  N(P)    & \\
                        &    \qquad    \textbf{if } g(\| RGB_p - RGB_q \|_2) \cdot \theta_q^t > \theta_p^t \\
                        &       \qquad \qquad l_p^{t+1} =  l_q^{t}  & \\
                        & \qquad  \qquad  \theta_p^{t+1} = g(\| RGB_p - RGB_q \|_2) \cdot \theta_q^t  \\
                         & \qquad     \textbf{end }  & \\
                        & \textbf{end }                         &\\
\textbf{end }\\
\end{aligned}
```
Where q is a pixel in the neighbourhood of p, l is the label of each pixel, θ is
the current strength of each pixel and RGB is the RGB vector of the pixel. g is
defined as ``g(x)=1-\dfrac{x}{\text{max}\|RGB\|}``.

An example of a custom rule for Lab colour is defined below:

```math
\begin{aligned}
\textbf{for } \forall p &  \in  P                               &\\
                        & l_p^{t+1} =  l_p^{t}                  &\\
                        & \theta_p^{t+1} =  \theta_p^{t}        &\\
                        & \textbf{for } \forall q  \in  N(P)    & \\
                        &    \qquad    \textbf{if } g(\| Lab_p - Lab_q \|_2) \cdot \theta_q^t > \theta_p^t \\
                        &       \qquad \qquad l_p^{t+1} =  l_q^{t}  & \\
                        & \qquad  \qquad  \theta_p^{t+1} = g(\| Lab_p - Lab_q \|_2) \cdot \theta_q^t  \\
                         & \qquad     \textbf{end }  & \\
                        & \textbf{end }                         &\\
\textbf{end }\\
\end{aligned}
```

where ``g(x)=1-\dfrac{x}{\text{max}\|Lab\|}``.
This would be implemented as per follows:

```julia

#calculate maxLab as needed by rule
function calculate_maxLab(LAB_color_vector::AbstractArray)
    maxLab = 0
    for i in CartesianIndices(feature_vector)
        current_Lab = sqrt(LAB_color_vector[i].l^2 + LAB_color_vector[i].a^2 + LAB_color_vector[i].b^2)
        if current_Lab > maxLab
            maxC = current_Lab
        end
    end
    return maxLab
end

#calculates the adjusted strength as per rule
function example_LAB_rule(θ::Array{Float64,1}, LAB_color_vector::AbstractArray, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, maxLab)

    LabTarget = LAB_color_vector[target_pixel]
    LabAttacker = LAB_color_vector[attacking_pixel]

    #calculate difference between LAB vectors
    LABdiff=Lab(LabTarget.l-LabAttacker.l,LabTarget.a-LabAttacker.a,LabTarget.b-LabAttacker.b)

    #find the absolute of the difference
    absLABdiff=sqrt(LABdiff.l^2+LABdiff.a^2+LABdiff.b^2)

    #calculate strength
    adjusted_strength = (1-(absLABdiff/maxLab))*θ[attacking_pixel]
    return adjusted_strength
end
```

The rule can then be passed to `Growcut` as per following:

```
l=segment_image(GrowCut(), img, clicks, rule=(example_LAB_rule,calculate_maxLab))
```

# Reference
1. V. Vezhnevets and V. Konouchine, "“GrowCut” - Interactive Multi-Label N-D Image Segmentation By Cellular Automata", in Graphicon, Novosibirsk Akademgorodok, Russia, 2005.
"""
function segment_image(Algorithm::GrowCut, feature_vector::AbstractArray, seeds::AbstractArray{Int, 2}, t1::Int=9, t2::Int=9; max_iter::Int=1000, converge_at::Int=1, rule::Tuple{Function, Function}=(colour_diff, find_maxRGB))
    #initialize values
    calculate_adjusted_strength = rule[1]
    extra_function = rule[2]
    extras = extra_function(feature_vector)
    l = copy(seeds)
    E = zeros(Int, axes(l))
    θ = set_strength(l)
    lₜ₊₁ = copy(seeds)
    Eₜ₊₁ = zeros(Int, axes(l))
    θₜ₊₁ = set_strength(l)
    regions = maximum(seeds)
    iter = 0
    count = length(l)
    changed = Array{Tuple{UnitRange{Int},UnitRange{Int}},1}(undef,1)
    changedₜ₊₁ = Array{Tuple{UnitRange{Int},UnitRange{Int}},1}(undef,0)
    rₘ, cₘ = size(l)
    changed[1] = 1:rₘ, 1:cₘ

    #overflow warning
    if typeof(feature_vector) == Array{RGB,2} && typeof(feature_vector) != Array{RGB{Float64},2}
        @warn "feature_vector is RGB and not of type RGB{Float64}. This may cause overflow errors."
    end

    #iterate till convergence or maximum iterations reached
    while count > converge_at && iter < max_iter
        iter += 1
        count = 0
        copyto!(θₜ₊₁, θ)
        copyto!(lₜ₊₁, l)
        copyto!(Eₜ₊₁, E)
        #loop through active pixel neighbourhoods (all pixels on first iteration)
        for j in CartesianIndices(changed)
            @inbounds for i in CartesianIndices(changed[j])
                r,c=i.I
                r₀ = max(r-1, 1)
                r₁ = min(r+1, rₘ)
                c₀ = max(c-1, 1)
                c₁ = min(c+1, cₘ)
                Nbound = r₀:r₁, c₀:c₁
                Eₜ₊₁[i] = count_enemy(l,i,Nbound)
                if E[i] < t2
                    θₜ₊₁, lₜ₊₁, count, changedₜ₊₁ = update_pixel(θ, θₜ₊₁, l, lₜ₊₁, feature_vector, E, i, extras, t1, count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
                else
                    θₜ₊₁, lₜ₊₁, count, changedₜ₊₁ = occupy_pixel(θ, θₜ₊₁, l, lₜ₊₁, feature_vector, i, extras,count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
                end
            end
        end

        #update values
        changed = changedₜ₊₁
        changedₜ₊₁ = empty(changedₜ₊₁)
        E = Eₜ₊₁
        θ = θₜ₊₁
        l = lₜ₊₁
    end
    return l
end
