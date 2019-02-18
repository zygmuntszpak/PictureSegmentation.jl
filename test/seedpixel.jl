@testset "seedpixel" begin
    img = testimage("toucan")
    clicks = zeros(Int,axes(img))
    set_seed_pixels!(clicks, img)
    @test true

    clicks = zeros(Int,axes(img))
    set_seed_pixels!(clicks, img)
    @test true
end
