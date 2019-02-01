"""
Documentation goes here
"""
function new_slic(img, k)

    nrow, ncol = size(img)
    N = length(img)
    s = round(Int, sqrt(N / k))
    error = 0.0

    # Initalise arrays for the first time.
    counts = zeros(k)
    totals = zeros(k, 5)
    centers = Array{CartesianIndex}(undef, k)
    center_colors = Array{Lab{Float64}}(undef, k)
    pixel_associactions = zeros(Int, nrow, ncol)
    distances = fill(Inf, size(img))
    initialise_centers!(centers, s, k, nrow, ncol)
    seed_locations!(centers, img)

    # # maxiter add keyword argument
    # for i = 1:9
    #     assign_labels!(centers,center_colors, img, pixel_associactions, counts, distances, totals, s)
    #     centers,center_colors,img = calc_new_centers(centers,center_colors,counts,totals,img)
    #     fill!(counts,0)
    #     fill!(totals,0.0)
    #     fill!(pixel_associactions,0)
    #     fill!(distances,Inf)
    # end

    # pixel_associactions,counts,distances,totals = assign_labels!(centers, center_colors, img, pixel_associactions, counts, distances, totals,s)
    # centers,center_colors,img=calc_new_centers(centers,center_colors,counts,totals,img)
    #
    # # Create the superpixels
    # img2 = similar(img)
    # #img2 = copy(img)
    # for i in CartesianIndices(img2)
    #     if pixel_associactions[i] !=0
    #         img2[i] = center_colors[pixel_associactions[i]]
    #     end
    # end
    # for i in centers
    #     if i != CartesianIndex(0,0)
    #         img2[i] = Lab{Float64}(0,128,-128)
    #     end
    # end
    # return img2

end

function calculate_gradient_magnitude(img::AbstractArray)
    grad_y, grad_x = imgradients(RGB.(img), KernelFactors.sobel, "replicate")
    magnitudes = magnitude(grad_x, grad_y)
end

# Calclates colour distance between 2 pixels.
function d_lab(𝑙ₖ::Float64, 𝑙ᵢ::Float64, 𝑎ₖ::Float64, 𝑎ᵢ::Float64, 𝑏ₖ::Float64, 𝑏ᵢ::Float64)
    return sqrt( (𝑙ₖ - 𝑙ᵢ)^2 + (𝑎ₖ - 𝑎ᵢ)^2 + (𝑏ₖ - 𝑏ᵢ)^2 )
end
# Calculates xy distance between 2 pixels.
function d_xy(𝑥ₖ::Real, 𝑥ᵢ::Real, 𝑦ₖ::Real, 𝑦ᵢ::Real)
    return sqrt( (𝑥ₖ - 𝑥ᵢ)^2 + (𝑦ₖ - 𝑦ᵢ)^2 )
end

# Calculate the distance measure between two CartesianIndexes.
function calc_dist(img,center::CartesianIndex, px::CartesianIndex,s)
    return d_lab(img[center].l, img[px].l, img[center].a, img[px].a, img[center].b, img[px].b) + (10 * d_xy(center[2], px[2], center[1], px[1]) ) / s
end

#=Calculates the top-left and bottom-right bounds of a neighbourhood
of width w x w around the pixel passed in.
=#
function get_neighbourhood(center::CartesianIndex, w::Integer, img::AbstractArray)
    nrow, ncol = size(img)
    r, c  = center.I
    r₀ = max(r - w, 1)
    r₁ = min(r + w, nrow)
    c₀ = max(c - w, 1)
    c₁ = min(c + w, ncol)
    CartesianIndices((r₀:r₁, c₀:c₁))
end

function assign_labels!(centers, center_colors, img, pixel_associactions, counts, distances, totals, s)
    for i = 1:length(centers)
        if centers[i] != CartesianIndex(0,0)
            a = center_colors[i]
            c₁, c₂ = centers[i].I
            search_area = get_neighbourhood(centers[i], s, img)
            for pixel in search_area
                b = img[pixel]
                dlab = sqrt((a.l - b.l)^2 + (a.a - b.a)^2 + (a.b - b.b)^2)
                dxy = sqrt((c₂ - pixel[2])^2 + (c₁ - pixel[1])^2)
                temp_dist =  dlab + (10/s) * dxy
                if temp_dist < distances[pixel]
                    r, c = pixel.I
                    # If the pixel was previously associated with another center
                    if pixel_associactions[pixel] != 0
                        remove_from_centroid!(img[pixel], r, c, pixel_associactions[pixel],  counts, totals)
                    end
                    # Associate pixel with new center
                    pixel_associactions[pixel] = i
                    # Update shortest distance
                    distances[pixel] = temp_dist
                    add_to_centroid!(img[pixel], r, c, i, counts, totals)
                end
            end
        end
    end
    for i in eachindex(counts)
        if counts[i]<=0
            centers[i]=CartesianIndex(0,0)
        end
    end
    return pixel_associactions,counts,distances,totals
end

function remove_from_centroid!(pixel, r, c, index,  counts, totals)
    counts[index] -= 1
    totals[index,1] -= pixel.l
    totals[index,2] -= pixel.a
    totals[index,3] -= pixel.b
    totals[index,4] -= r
    totals[index,5] -= c
end

function add_to_centroid(pixel, r, c, index,  counts, totals)
    counts[index] += 1
    totals[index,1] += pixel.l
    totals[index,2] += pixel.a
    totals[index,3] += pixel.b
    totals[index,4] += r
    totals[index,5] += c
end

function calc_new_centers(centers,center_colors,counts,totals,img)
    # Compute new centers
    for i in eachindex(centers)
        if centers[i] != CartesianIndex(0,0)
            # Assign new centers to their respective arrays.
            center_colors[i] = Lab{Float64}(totals[i,1]/counts[i],totals[i,2]/counts[i],totals[i,3]/counts[i])
            centers[i] = CartesianIndex(round(Int,totals[i,4]/counts[i]),round(Int,totals[i,5]/counts[i]))
        end
    end
    return centers, center_colors, img
end

#= Generate starting locations for centers, at regularly
spaced intervals.
=#
function initialise_centers!(centers, s, K, nrow, ncol)
    k = 0
    for c = 1:s:ncol
        for r = 1:s:nrow
            if k != K
                k += 1
                centers[k] = CartesianIndex(r,c)
            end
        end
    end
end

function seed_locations!(centers, img)
    gradient_magnitude = calculate_gradient_magnitude(img)
    nrow, ncol = size(img)
    for i in eachindex(centers)
        r, c  = centers[i].I
        r₀ = max(r - 1, 1)
        r₁ = min(r + 1, nrow)
        c₀ = max(c - 1, 1)
        c₁ = min(c + 1, ncol)
        minval, pos = findmin(gradient_magnitude[r₀:r₁, c₀:c₁])
        centers[i] += (CartesianIndex(pos) - CartesianIndex(r₁ - r₀, c₁ - c₀))
    end
end
