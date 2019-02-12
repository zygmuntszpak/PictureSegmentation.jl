#function used for adjusting strength of pixel
function g(x, maxRGB)
    return 1 - (x / maxRGB)
end

#find maximum colour vector
function find_maxRGB(feature_vector)
    maxRGB = 0
    for i in CartesianIndices(feature_vector)
        current_RGB = sqrt(feature_vector[i].r^2 + feature_vector[i].g^2  + feature_vector[i].b^2)
        if current_RGB > maxRGB
            maxRGB = current_RGB
        end
    end
    return maxRGB
end

function count_enemy(l, target_pixel::CartesianIndex, NBound)
    num_enemy = 0
    @inbounds for j in CartesianIndices(NBound)
         if j != CartesianIndex(target_pixel) && l[j] != l[target_pixel] && l[j] != 0
            num_enemy += 1
        end
    end
    return num_enemy
end

#default rule for GrowCut() uses decreasing function and relative difference in
#colour to adjust strengths.
function colour_diff(θ, feature_vector, target_pixel::CartesianIndex, attacking_pixel::CartesianIndex, extras)
    Cdiff = feature_vector[target_pixel] - feature_vector[attacking_pixel]
    absCdiff = sqrt(Cdiff.r^2 + Cdiff.g^2 + Cdiff.b^2)
    adjusted_strength = g(absCdiff, extras) * θ[attacking_pixel]
    return adjusted_strength
end

#std update of pixel
function update_pixel(θ, θₜ₊₁, l, lₜ₊₁, feature_vector, E, target_pixel::CartesianIndex, extras, t1, count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
    @inbounds for j in CartesianIndices(Nbound)
        adjusted_strength = calculate_adjusted_strength(θ, feature_vector, target_pixel, j, extras)
        change = false
        if adjusted_strength > θ[target_pixel] && E[j] < t1 && j != target_pixel
            lₜ₊₁[target_pixel] = l[j]
            θₜ₊₁[target_pixel] = adjusted_strength
            count += 1
            if change == false
                push!(changedₜ₊₁, Nbound)
                change = true
            end
        end
    end
    return θₜ₊₁, lₜ₊₁, count, changedₜ₊₁
end

#update of pixel if surrounded by too many enemies
function occupy_pixel(θ, θₜ₊₁, l, lₜ₊₁, feature_vector, target_pixel::CartesianIndex, extras, count, Nbound, changedₜ₊₁, calculate_adjusted_strength)
    θtemp = 1.0
    location = target_pixel
    ltemp = l[target_pixel]
    @inbounds for j in CartesianIndices(Nbound)
        if j != target_pixel && θ[j] < θtemp && l[j] != l[target_pixel]
            θtemp = θ[j]
            location = j
        end
    end
    θₜ₊₁[target_pixel] = calculate_adjusted_strength(θ, feature_vector, target_pixel, location, extras)
    lₜ₊₁[target_pixel] = l[location]
    count += 1
    push!(changedₜ₊₁, Nbound)
    return θₜ₊₁, lₜ₊₁, count, changedₜ₊₁
end

#sets initial strengths
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

Outputs template for a new rule into the REPL.

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
