@testset "growcut" begin
    test = zeros(RGB{Float64},100,100)
    for i = 25:50
        for j = 25:50
            test[i,j]=RGB(1,0,0)
        end
    end
    for i = 60:90
        for j = 60:65
            test[i,j]=RGB(1,0,1)
        end
    end
    for i in CartesianIndices(test)
        if (i[1]-25)^2+(i[2]-65)^2 <= 20^2
            test[i]=RGB(0,1,1)
        end
    end
    test
    testClicks = zeros(Int,axes(test))
    testClicks[52,52]=1
    testClicks[25,75]=2
    testClicks[62,62]=3
    testClicks[40,40]=4
    l=segment_image(GrowCut(),test,testClicks,9,9)

    @test l[75,25] == 1
    @test l[30,50] == 2
    @test l[80,62] == 3
    @test l[30,30] == 4

    img = testimage("toucan")
    img = RGB{Float64}.(img)
    clicks = zeros(Int,axes(img))
    clicks[16, 104]=1
    clicks[67, 66]=1
    clicks[77, 31]=1
    clicks[97, 77]=1
    clicks[76, 106]=1
    clicks[30, 99]=1
    clicks[18, 77]=1
    clicks[74, 85]=1
    clicks[26, 64]=1
    clicks[34, 67]=1
    clicks[26, 49]=1
    clicks[63, 17]=1
    clicks[98, 40]=1
    clicks[100, 18]=1
    clicks[97, 56]=1
    clicks[108, 8]=1
    clicks[35, 64]=1
    clicks[50, 91]=2
    clicks[23, 98]=2
    clicks[25, 27]=2
    clicks[128, 29]=2
    clicks[127, 115]=2
    clicks[46, 137]=2
    l=segment_image(GrowCut(),img,clicks,8,8)

    @test l[55, 50] == 1
    @test l[87, 13] == 1
    @test l[107, 54] == 2
    @test l[105, 153] == 2

    mask = make_contour(l)
    @test maximum(mask) == 1
    @test minimum(mask) == 0

    img2 = convert_labels(mask)
    @test img2[1,1] == RGB{Float64}(0.5,1.0,0.0)
    @test img2[20,20] == RGB{Float64}(0.5,1.0,0.0)
    @test img2[42,24] == RGB{Float64}(0.5,1.0,0.0)
    @test img2[21,11] == RGB{Float64}(0.5,1.0,0.0)
    @test img2[101,42] == RGB{Float64}(0.5,1.0,0.0)
end
