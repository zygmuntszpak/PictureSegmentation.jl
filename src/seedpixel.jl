function set_seed_pixels(labels::Array{Int,2}, img::AbstractArray)
    scene = Scene()
    image!(img, show_axis = false)
    clicks = Node(Point2f0[])
    region = 1
    endSet=true
    on(events(scene).mousedrag) do buttons
        if ispressed(scene, Mouse.left)
            pos = to_world(scene, Point2(scene.events.mouseposition[]))
            posInt = (round(Int,(pos[1]/axes(img)[2][end])*axes(img)[1][end]),round(Int,(pos[2]/axes(img)[1][end])*axes(img)[2][end]))
            @show posInt, axes(img)
            if minimum(posInt)>1 && posInt[1]<axes(img)[1][end]-1 && posInt[2]<axes(img)[2][end]-1
                push!(clicks, push!(clicks[], pos))
                labels[posInt[1],posInt[2]]=region
                @show labels[posInt[1],posInt[2]]
            end
        end
        return
    end
    on(scene.events.keyboardbuttons) do buttons
        if ispressed(scene, Keyboard.up)
            region += 1
            @show region
        end
        if ispressed(scene, Keyboard.down)
            if region!=1
                region -= 1
                @show region
            end
        end
        if ispressed(scene, Keyboard.enter)
            endSet=false
        end
        return
    end
    scatter!(scene, clicks, color = :red, marker = '.', markersize = 3,show_axis = false)
end
