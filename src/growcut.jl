#function used for adjusting strength of pixel
function g(x,maxC)
    return 1-(x/maxC)
end

#find maximum colour vector
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

#std update of pixel
function update_pixel(Nθ,Nθₜ₊₁,Nl,Nlₜ₊₁,Nimg,NE,target_pixel::CartesianIndex,maxC,t1,count,Nbound,changedₜ₊₁)
    @inbounds for j in CartesianIndices(Nbound)
        Cdiff=Nimg[target_pixel]-Nimg[j]
        absCdiff=sqrt(Cdiff.r^2+Cdiff.g^2+Cdiff.b^2)
        adjusted_strenth = g(absCdiff,maxC)*Nθ[j]
        change = false
        if adjusted_strenth>Nθ[target_pixel] && NE[j]<t1 && j != target_pixel
            Nlₜ₊₁[target_pixel]=Nl[j]
            Nθₜ₊₁[target_pixel]=adjusted_strenth
            count +=1
            if change == false
                push!(changedₜ₊₁,Nbound)
                change = true
            end
        end
    end
    return Nθₜ₊₁,Nlₜ₊₁,count,changedₜ₊₁
end

#update of pixel if sorounded by to many enemies
function occupy_pixel(Nθ,Nθₜ₊₁,Nl,Nlₜ₊₁,Nimg,target_pixel::CartesianIndex,maxC,count,Nbound,changedₜ₊₁)
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
    push!(changedₜ₊₁,Nbound)
    return Nθₜ₊₁,Nlₜ₊₁,count,changedₜ₊₁
end

#sets initial strengths
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
    #initilize values
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
    changed=Array{Tuple{UnitRange{Int64},UnitRange{Int64}},1}(undef,1)
    changedₜ₊₁=Array{Tuple{UnitRange{Int64},UnitRange{Int64}},1}(undef,0)
    changed[1]=1:size(img)[1],1:size(img)[2]

    #iterate till convergance or maximum iterations reached
    while count>converge_at && iter < max_iter
        iter+=1
        count = 0
        copyto!(θₜ₊₁,θ)
        copyto!(lₜ₊₁,l)
        copyto!(Eₜ₊₁,E)

        #loop through active pixel neighbourhoods (all pixels on first iteration)
        for j in CartesianIndices(changed)
            @inbounds for i in CartesianIndices(changed[j])
                Nbound=max(i[1]-1,1):min(i[1]+1,axes(img)[1][end]),max(i[2]-1,1):min(i[2]+1,axes(img)[2][end])
                Eₜ₊₁[i]=count_enemy(l,i,Nbound)
                if Eₜ₊₁[i] < t2
                    θₜ₊₁,lₜ₊₁,count,changedₜ₊₁=update_pixel(θ,θₜ₊₁,l,lₜ₊₁,img,E,i,maxC,t1,count,Nbound,changedₜ₊₁)
                else
                    θₜ₊₁,lₜ₊₁,count,changedₜ₊₁=occupy_pixel(θ,θₜ₊₁,l,lₜ₊₁,img,i,maxC,count,Nbound,changedₜ₊₁)
                end
            end
        end

        #update values
        changed=changedₜ₊₁
        changedₜ₊₁=similar(changedₜ₊₁,0)
        E=Eₜ₊₁
        θ=θₜ₊₁
        l=lₜ₊₁
    end
    return l
end
