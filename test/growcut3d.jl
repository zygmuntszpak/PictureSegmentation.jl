@testset "growcut3d" begin
    img = generate_3d_img()
    display_3d(img)
    @test true
    clicks=zeros(Int,axes(img))
    clicks[50,50,10] = 1
    clicks[50,50,90] = 1
    clicks[12,12,12] = 2
    clicks[38,38,38] = 2
    clicks[5,5,5] = 3
    clicks[90,90,90] = 3
    clicks[90,5,90] = 3
    clicks[5,90,5] = 3
    l = segment_image(GrowCut(),img,clicks,27,27)
    @test l[50,50,50] == 1
    @test l[55,45,98] == 1
    @test l[25,25,25] == 2
    l = segment_image(GrowCut(),img,clicks,26,26)
    @test l[11,11,30] == 2
    @test l[5,5,90] == 3
    @test l[90,90,5] == 3
end
