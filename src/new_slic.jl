"""
Documentation goes here
"""
function new_slic(img, k)

    no_rows, no_columns = size(img)
    n = length(img)
    s = round(Int,sqrt(n/k))

    img_height, img_width = size(img)
    error = 0.0

    # Initalise arrays for the first time
    counts = zeros(k)
    totals = zeros(1,k,5)
    centers = Array{CartesianIndex}(undef,k)
    center_colors = Array{Lab{Float64}}(undef,k)
    pixel_associactions = zeros(Int,img_height,img_width)

    distances = fill(Inf,size(img))

    # Initial stuff
    centers=initialise_centers(centers,s,k,no_rows, no_columns)
    centers=seed_locations(centers,img)

    for i=1:9
        pixel_associactions,counts,distances,totals=calculate_distances(centers,img,pixel_associactions,counts,distances,totals,s)
        centers,center_colors,img = calc_new_centers(centers,center_colors,counts,totals,img)
        fill!(counts,0)
        fill!(totals,0.0)
        fill!(pixel_associactions,0)
        fill!(distances,Inf)
    end

    pixel_associactions,counts,distances,totals=calculate_distances(centers,img,pixel_associactions,counts,distances,totals,s)
    centers,center_colors,img=calc_new_centers(centers,center_colors,counts,totals,img)

    # Create the superpixels
    img2 = similar(img)
    #img2 = copy(img)
    for i in CartesianIndices(img2)
        if pixel_associactions[i] !=0
            img2[i] = center_colors[pixel_associactions[i]]
        end
    end
    for i in centers
        if i != CartesianIndex(0,0)
            img2[i] = Lab{Float64}(0,128,-128)
        end
    end
    return img2

end

function calc_gradient(img)::Array{Float64}
    rgb_img = RGB.(img)
    grad_y, grad_x = imgradients(rgb_img,KernelFactors.sobel, "replicate")
    magnitudes = magnitude(grad_x, grad_y)
    return magnitudes
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
    return d_lab(img[center].l, img[px].l,img[center].a, img[px].a,img[center].b, img[px].b) + (10 * d_xy(center[2], px[2], center[1], px[1]) ) / s
end

#=Calculates the top-left and bottom-right bounds of a neighbourhood
of width w x w around the pixel passed in.
=#
function calc_neighbourhood(pixel::CartesianIndex, w,img)
    return CartesianIndices((max(pixel[1] - w, 1):min(pixel[1] + w, size(img)[1]), max(pixel[2] - w, 1): min(pixel[2] + w, size(img)[2])))
end

function calculate_distances(centers,img,pixel_associactions,counts,distances,totals,s)
    temp_dist = 0.0
    for i = 1:size(centers)[1]
        if centers[i] != CartesianIndex(0,0)
            a = img[centers[i]]
            c1 = centers[i][2]
            c2 = centers[i][1]
            search_area = calc_neighbourhood(centers[i],s,img)
            # Initialise shortest distance
            for pixel in search_area
                b = img[pixel]
                dlab=sqrt((a.l-b.l)^2+(a.a-b.a)^2+(a.b-b.b)^2)
                dxy=sqrt((c2-pixel[2])^2+(c1-pixel[1])^2)
                temp_dist =  dlab + (1/s) * dxy
                if temp_dist < distances[pixel]
                    pixel_data = img[pixel]
                    # IF the pixel was previously associated with another center
                    if pixel_associactions[pixel] != 0
                        # Store the previously associated center
                        prev_center = pixel_associactions[pixel]
                        # Take away the count
                        counts[prev_center] -= 1
                        # How to do this in a more efficient way?
                        # Remove pixel's data
                        totals[1,prev_center,1] -= pixel_data.l
                        totals[1,prev_center,2] -= pixel_data.a
                        totals[1,prev_center,3] -= pixel_data.b
                        totals[1,prev_center,4] -= pixel[1]
                        totals[1,prev_center,5] -= pixel[2]
                    end
                    # Associate pixel with new center
                    pixel_associactions[pixel] = i
                    # Update shortest distance
                    distances[pixel] = temp_dist
                    # Update counts
                    counts[i] +=1
                    # Update average calculations
                    totals[1,i,1] += pixel_data.l
                    totals[1,i,2] += pixel_data.a
                    totals[1,i,3] += pixel_data.b
                    totals[1,i,4] += pixel[1]
                    totals[1,i,5] += pixel[2]
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

function calc_new_centers(centers,center_colors,counts,totals,img)
    # Compute new centers
    for i in eachindex(centers)
        if centers[i] != CartesianIndex(0,0)
            # Assign new centers to their respective arrays.
            center_colors[i] = Lab{Float64}(totals[1,i,1]/counts[i],totals[1,i,2]/counts[i],totals[1,i,3]/counts[i])
            centers[i] = CartesianIndex(round(Int,totals[1,i,4]/counts[i]),round(Int,totals[1,i,5]/counts[i]))
        end
    end
    return centers,center_colors,img
end

#= Generate starting locations for centers, at regularly
spaced intervals.
=#
function initialise_centers(centers,s,k,no_rows, no_columns)
    row_pos = col_pos = 1
    for i = 1:k
        col_pos += s
        if col_pos > no_columns
            row_pos = min(row_pos +=s, no_rows)
            col_pos = 1
        end
        centers[i] = CartesianIndex(row_pos,col_pos)
    end
    return centers
end

function seed_locations(centers,img)
    # Calculate gradients
    gradients = calc_gradient(img)
    min_gradient = CartesianIndex(0,0)
    for i in eachindex(centers)
        indexes = CartesianIndices((max(centers[i][1] - 1, 1):min(centers[i][1] + 1, size(img)[1]), max(centers[i][2] - 1, 1): min(centers[i][2] + 1, size(img)[2])))
        min_gradient = findmin(gradients[indexes])[2]
        centers[i] = CartesianIndex(min_gradient[1]+max(centers[i][1] - 1, 0),min_gradient[2]+max(centers[i][2] - 1, 0))
        #img[centers[i]]=Lab{Float64}(100,-128,-128)
    end
    return centers
end
