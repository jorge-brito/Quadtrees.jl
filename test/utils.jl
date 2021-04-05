@testset "Utils" begin
    @test Quadtrees.distance²((3, 4), (0, 0)) == 25
    @test Quadtrees.distance((3, 4), (0, 0)) == 5
    
    for x in 45:55
        for y in 45:55
            should_be_true = (x, y) in Rect(50, 50, 10, 10)
            should_be_false = (x, y) in Rect(0, 0, 10, 10)
            @test should_be_true == true
            @test should_be_false == false
        end
    end

    @test_throws ErrorException [0, 0] in Rect(0, 0, 10, 10)
    
    Quadtrees.position(::Nothing) = nothing

    @test_throws AssertionError nothing in Rect(0, 0, 10, 10)

    for x in 45:65
        for y in 45:55
            @test Rect(50, 50, x, y) in Rect(50, 55, 10, 20)
            @test !(Rect(0, 0, 1, 1) in Rect(5, 5, random(5), random(5)))
        end
    end
end

@testset "Intersections" begin
    @init "Intersections test" 800 800
    @layout aside(:v, 230)
    @create @options begin
        use_rectangle = false
        radius = (1:400, 100)
        spacing = (10, 1:50)
        parameters = @nolabel (
            rows = (1:100, 15),
            cols = (1:100, 15),
            margin = (1:50, 20)
        )
    end

    mouse = Ref{Point}(O)
    
    @use function update()
        background("black")
        origin()
        w, h = @width, @height

        rows, cols, margin = Int.(getindex.(parameters))
        tiles = Tiler(@width, @height, rows, cols; margin)
        tw = tiles.tilewidth - spacing[]
        th = tiles.tileheight - spacing[]

        rects = [Rect(pos.x, pos.y, tw, th) for pos in first.(tiles)]
        mousepos = mouse[] - (w/2, h/2)

        if use_rectangle[]
            range = Rect(mousepos..., radius[], radius[])
        else
            range = Quadtrees.Circle(mousepos..., radius[])
        end

        sethue("yellowgreen")
        draw(range, :stroke)

        for rect in rects
            sethue("white")
            rect in range && sethue("yellowgreen")
            draw(rect, :stroke)
        end
    end

    @use function mousemove(event)
        mouse[] = event.pos
    end

    start(; async = true)
    destroy(@window)
end