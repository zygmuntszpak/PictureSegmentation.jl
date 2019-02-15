# Used for adjusting strength of pixel.
function g(x, max_rgb)
    return 1 - (x / max_rgb)
end

# find maximum colour vector
function find_maximum(rgb::AbstractArray)
    max_rgb = 0
    for i in CartesianIndices(rgb)
        current_RGB = sqrt(rgb[i].r^2 + rgb[i].g^2  + rgb[i].b^2)
        if current_RGB > max_rgb
            max_rgb = current_RGB
        end
    end
    return max_rgb
end

function count_enemy(labels, target_pixel::CartesianIndex, N₈)
    enemy_count = 0
    @inbounds for j in CartesianIndices(N₈)
         if j != target_pixel && labels[j] != labels[target_pixel] && labels[j] != 0
            enemy_count += 1
        end
    end
    return enemy_count
end

# default rule for GrowCut() uses decreasing function and relative difference in
# colour to adjust strengths.
function colour_differance(θ::AbstractArray, rgb::AbstractArray, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, extras)
    Cdiff = rgb[target_pixel] - rgb[attacking_pixel]
    absCdiff = sqrt(Cdiff.r^2 + Cdiff.g^2 + Cdiff.b^2)
    adjusted_strength = g(absCdiff, extras) * θ[attacking_pixel]
    return adjusted_strength
end

# std update of pixel
function update_pixel(θ::AbstractArray, θₜ₊₁::AbstractArray, labels::AbstractArray, labelsₜ₊₁::AbstractArray, feature_vector::AbstractArray, E::AbstractArray, target_pixel::CartesianIndex, extras, t1, count, N₈, changedₜ₊₁, calculate_adjusted_strength::Function)
    @inbounds for j in CartesianIndices(N₈)
        adjusted_strength = calculate_adjusted_strength(θ, feature_vector, target_pixel, j, extras)
        change = false
        if adjusted_strength > θ[target_pixel] && E[j] < t1 && j != target_pixel
            labelsₜ₊₁[target_pixel] = labels[j]
            θₜ₊₁[target_pixel] = adjusted_strength
            count += 1
            if change == false
                push!(changedₜ₊₁, N₈)
                change = true
            end
        end
    end
    return θₜ₊₁, labelsₜ₊₁, count, changedₜ₊₁
end

# update of pixel if surrounded by too many enemies
function occupy_pixel(θ, θₜ₊₁, labels, labelsₜ₊₁, feature_vector, target_pixel::CartesianIndex, extras, count, N₈, changedₜ₊₁, calculate_adjusted_strength)
    θmax = 1.0
    location = target_pixel
    ltemp = labels[target_pixel]
    @inbounds for j in CartesianIndices(N₈)
        if j != target_pixel && θ[j] < θmax && labels[j] != labels[target_pixel]
            θmax = θ[j]
            location = j
        end
    end
    θₜ₊₁[target_pixel] = calculate_adjusted_strength(θ, feature_vector, target_pixel, location, extras)
    labelsₜ₊₁[target_pixel] = labels[location]
    count += 1
    push!(changedₜ₊₁, N₈)
    return θₜ₊₁, labelsₜ₊₁, count, changedₜ₊₁
end

# sets initial strengths
function set_strength(label)
    θ = zeros(Float64, axes(label))
    for i in CartesianIndices(label)
        if label[i] > 0
            θ[i] = 1.0
        end
    end
    return θ
end

"""
```
help_rule_template()
```

Outputs the following template for a new rule into the REPL:

```julia
function your_rule(strengths::Array{Float64,1}, [your feature_vector]::AbstractArray, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, [your additional_values]::Any)
   # your rule goes here
   return adjusted_strength
end

function your_extra_stuff([your feature_vector]::AbstractArray
   #your calculations for any additional values goes here
   #if you need more then one value they can be in an array or wrapped into a tuple
   return additional_values
end
```

"""
function help_rule_template()
    println("function your_rule(strengths::Array{Float64,1}, [your feature_vector]::AbstractArray, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, [your additional_values]::Any)")
    println("   #your rule goes here")
    println("   return adjusted_strength")
    println("end")
    println("")
    println("function your_extra_stuff([your feature_vector]::AbstractArray")
    println("   #your calculations for any additional values goes here")
    println("   #if you need more then one value they can be in an array or wrapped into a tuple")
    println("   return additional_values")
    println("end")
    println("")
    println("Use create_rule() to print to new file")
end

"""
```
create_rule(file::AbstractString="newrule.jl")
```

Outputs template for a new rule into a file.

# Arguments

The function arguments are described in more detail below.

##  `name_of_rule`
An `AbstractString` specifying the file to put the function in. Note: this can
override file contents, recomended to create a new file.

"""
function create_rule(file::AbstractString="newrule.jl")
    write(file,"function your_rule(strengths::Array{Float64,1}, [your feature_vector]::AbstractArray, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, [your additional_values]::Any)\n",
    "   #your rule goes here\n",
    "   return adjusted_strength\n",
    "end\n",
    "\n",
    "function your_extra_stuff([your feature_vector]::AbstractArray\n",
    "   #your calculations for any additional values goes here\n",
    "   #if you need more then one value they can be in an array or wrapped into a tuple\n",
    "   return additional_values\n",
    "end")
end
