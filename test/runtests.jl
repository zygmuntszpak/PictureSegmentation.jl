using PictureSegmentation, Images, TestImages
using Test

function generate_3d_img()
    img=Array{RGB{Float64},3}(undef,100,100,100)
    for i in CartesianIndices(img)
        if (i[1]-50)^2 + (i[2]-50)^2 < (i[3]/4)^2
            img[i]=RGB(i[3]/100,0,1-(i[3]/100))
        else
            img[i]=RGB(0,0,0)
        end
    end
    for i = 10:40
        for j = 10:40
            for k = 10:40
                img[i,j,k] = RGB(0.25,0.66,0.02)
            end
        end
    end
    return img
end

@testset "PictureSegmentation.jl" begin
    include("growcut.jl")
    include("growcut3d.jl")
    include("seedpixel.jl")
end
