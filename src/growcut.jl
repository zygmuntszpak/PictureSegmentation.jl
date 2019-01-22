function g(x,maxC)
    return 1-(x/maxC)
end

function find_maxC(img)
    maxC = 0
    for i in CartesianIndices(img)
        C = sqrt(img[i].r^2 + img[i].g^2  + img[i].b^2)
        if C > maxC
            maxC = C
        end
    end
    return maxC
end

function count_enemy(Nl,target_pixel::CartesianIndex,NBound)
    num_enemy = 0
    @inbounds for j in CartesianIndices(NBound)
         if j != CartesianIndex(target_pixel) && Nl[j]!=Nl[target_pixel] && Nl[j]!=0
            num_enemy+=1
        end
    end
    return num_enemy
end

function update_pixel(Nθ,Nθₜ₊₁,Nl,Nlₜ₊₁,Nimg,NE,target_pixel::CartesianIndex,maxC,t1,count,Nbound)
    @inbounds for j in CartesianIndices(Nbound)
        Cdiff=Nimg[target_pixel]-Nimg[j]
        absCdiff=sqrt(Cdiff.r^2+Cdiff.g^2+Cdiff.b^2)
        adjusted_strenth = g(absCdiff,maxC)*Nθ[j]
        if adjusted_strenth>Nθ[target_pixel] && NE[j]<t1 && j != target_pixel
            Nlₜ₊₁[target_pixel]=Nl[j]
            Nθₜ₊₁[target_pixel]=adjusted_strenth
            count +=1
        end
    end
    return Nθₜ₊₁,Nlₜ₊₁,count
end

function occupy_pixel(Nθ,Nθₜ₊₁,Nl,Nlₜ₊₁,Nimg,target_pixel::CartesianIndex,maxC,count,Nbound)
    θtemp = 1.0
    imgtemp = Nimg[target_pixel]
    ltemp = Nl[target_pixel]
    @inbounds for j in CartesianIndices(Nbound)
        if j != target_pixel && Nθ[j] < θtemp && Nl[j] != Nl[target_pixel]
            θtemp = Nθ[j]
            imgtemp = Nimg[j]
            ltemp = Nl[j]
        end
    end
    Cdiff=Nimg[target_pixel]-imgtemp
    absCdiff=sqrt(Cdiff.r^2+Cdiff.g^2+Cdiff.b^2)
    Nθₜ₊₁[target_pixel]=g(absCdiff,maxC)*θtemp
    Nlₜ₊₁[target_pixel]=ltemp
    count+=1
    return Nθₜ₊₁,Nlₜ₊₁,count
end

function set_strength(label)
    θ = zeros(Float64,axes(label))
    for i in CartesianIndices(label)
        if label[i]>0
            θ[i]=1.0
        end
    end
    return θ
end

function segment_image(Algorithm::GrowCut,imgIn::AbstractArray{T} where T <: RGB, label::Array{Int}, t1::Int=9, t2::Int=9; max_iter::Int=1000, converge_at::Int=1)
    img=RGB{Float64}.(imgIn)
    maxC = find_maxC(img)
    l = copy(label)
    E = zeros(Int, axes(img))
    θ = set_strength(l)
    lₜ₊₁ = copy(label)
    Eₜ₊₁ = zeros(Int, axes(img))
    θₜ₊₁ = set_strength(l)
    regions=maximum(label)
    iter = 0
    count = length(img)
    while count>converge_at && iter < max_iter
        iter+=1
        #@show iter, count
        count = 0
        copyto!(θₜ₊₁,θ)
        copyto!(lₜ₊₁,l)
        copyto!(Eₜ₊₁,E)
        @inbounds for i in CartesianIndices(img)
            Nbound=max(i[1]-1,1):min(i[1]+1,axes(img)[1][end]),max(i[2]-1,1):min(i[2]+1,axes(img)[2][end])
            Eₜ₊₁[i]=count_enemy(l,i,Nbound)
            if Eₜ₊₁[i] < t2
                θₜ₊₁,lₜ₊₁,count=update_pixel(θ,θₜ₊₁,l,lₜ₊₁,img,E,i,maxC,t1,count,Nbound)
            else
                θₜ₊₁,lₜ₊₁,count=occupy_pixel(θ,θₜ₊₁,l,lₜ₊₁,img,i,maxC,count,Nbound)
            end
        end
        E=Eₜ₊₁
        θ=θₜ₊₁
        l=lₜ₊₁
    end
    img2 = similar(img)
    for i in CartesianIndices(img2)
        img2[i]=θ[i]*RGB(sin((l[i]/regions)*π)/2+0.5,sin((l[i]/regions)*π+π/2)/2+0.5,sin((l[i]/regions)*π+(3*π)/2)/2+0.5)
    end
    return img2
end
#lₚ
