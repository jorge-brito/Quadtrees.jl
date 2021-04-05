using Quadtrees
using Test, Alexya, Luxor

function draw(p::Point, size = 2)
    circle(p.x, p.y, size, :fill) 
end

draw((x, y)::Quadtrees.Point) = draw(Point(x, y))

function draw(r::Rect, action = :none)
    box(Point(r.x, r.y), r.w, r.h, action)
end

function draw(c::Quadtrees.Circle, action = :none)
    circle(Point(c.x, c.y), c.r, action)
end

function draw(qt::Quadtree; items = false)
    draw(qt.bounds, :stroke)

    if !isleaf(qt)
        draw.(qt.sections; items)
    end

    items && draw.(qt.items)
end


include("utils.jl")
include("quadtree.jl")
