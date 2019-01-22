using PictureSegmentation, Images, TestImages
using Test

@testset "PictureSegmentation.jl" begin
    include("growcut.jl")
    include("seedpixel.jl")
end
