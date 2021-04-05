@testset "Quadtree.jl" begin
    width, height = 800, 800
    origin = (width/2, height/2)

    @init "Quadtree test 1" width height
    @layout aside(:v, 250)

    @create @options begin
        capacity = (4, 1:1000)
        search_radius = (200, 1:800)
        reset = Button("Reset", @hexpand)
    end

    Quadtrees.position(p::Point) = (p.x, p.y)

    pointlist = [randompoint(0, 0, width, height) for i in 1:500]

    mouse = Ref{Point}()

    onevent(:clicked, reset) do 
        empty!(pointlist)
    end

    @use function update()
        k = floor(Int, capacity[])
        qtree = Quadtree{Point}(origin, width, height, k)
        append!(qtree, pointlist)

        background("black")
        sethue("white")
        draw(qtree, items = true)
        
        if !ismissing(mouse)
            x, y = mouse[]
            r = search_radius[]
            setcolor"yellowgreen"
            circle(x, y, r, :stroke)
            draw.(search(qtree, x, y, r), 4)
        end
    end

    @use function mousemove(event)
        mouse[] = event.pos
    end

    @use function mouse1motion((pos, x, y))
        push!(pointlist, pos)
    end

    start()
end
