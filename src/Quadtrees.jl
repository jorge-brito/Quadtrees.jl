module Quadtrees

export position,
    Boundary,
    Rect,
    Circle,
    Quadtree,
    subdivide!,
    isleaf,
    query,
    query!,
    search,
    search!

import Base: push!, insert!, append!, length, in, +, -, *, /

const Point = Tuple{Real, Real}

"""
        distance²((x₁, y₁), (x₂, y₂)) -> Real

Returns the square distance between two points.

```math
d²(p₁, p₂) = (x₂ - x₁)² + (y₂ - y₁)²
```
"""
distance²((x₁, y₁)::Point, (x₂, y₂)::Point) = (x₂ - x₁) ^ 2 + (y₂ - y₁) ^ 2
"""
        distance((x₁, y₁), (x₂, y₂)) -> Real

Returns the distance between two points.

```math
distance(p₁, p₂) = \\sqrt{(x₂ - x₁)² + (y₂ - y₁)²}
```
"""
distance(P₁::Point, P₂::Point) = √distance²(P₁, P₂)

"""
        position(value::T) -> Tuple{Real, Real}

This function is used for the [in](@ref) method for determine
the intersections between the [Boundary](@ref) objects and points.

This function is not mented to be used directly, but to be extended
for the objects `T` that your [quadtree](@ref) carries.

This function **must** return an tuple of two [Real](@ref) numbers.

For example,

```julia
mutble struct MyType
    pos::Vector{Real}
    # other fields...
end

Quadtrees.position(obj::MyType) = (obj.pos[1], obj.pos[2])
```
"""
function position(::T) where {T}
    throw(ErrorException("You need to implement the Quadtrees.position method for the type $T"))
end

position((x, y)::Point) = (x, y)

function _position(value::T) where {T}
    pos = position(value)
    @assert typeof(pos) <: Point "The return value of the position method must be 
    a tuple of two Real numbers, but got type $(typeof(pos)) instead."
    return pos;
end


abstract type Boundary end
"""
Represents a 2D rectangle boundary.
"""
struct Rect <: Boundary
    x::Real
    y::Real
    w::Real
    h::Real
end

+(r::Rect, (x, y)::Point) = Rect(r.x + x, r.y + y, r.w, r.h)
-(r::Rect, (x, y)::Point) = Rect(r.x - x, r.y - y, r.w, r.h)
*(r::Rect, n::Real) = Rect(r.x, r.y, n * r.w, n * r.h)
/(r::Rect, n::Real) = Rect(r.x, r.y, r.w / n, r.h / n)

in(item::T, R::Rect) where {T} = begin
    x, y = _position(item)
    rx, ry = R.w / 2, R.h / 2
    
    x ≥ R.x - rx &&
    x ≤ R.x + rx &&
    y ≥ R.y - ry &&
    y ≤ R.y + ry
end

function in(A::Rect, B::Rect)
    Arx, Ary = A.w / 2, A.h / 2
    Brx, Bry = B.w / 2, B.h / 2
    return !(
        A.x - Arx > B.x + Brx ||
        A.x + Arx < B.x - Brx ||
        A.y - Ary > B.y + Bry ||
        A.y + Ary < B.y - Bry
    )
end

"""
        vertices(rect) -> Vector

Returns the vertices of a rectangle.
"""
function vertices(R::Rect)
    x, y = R.x, R.y
    rx, ry = R.w / 2, R.h / 2
    return Point[
        # Top-Left corner
        (x - rx, y - ry),
        # Top-Right corner
        (x + rx, y - ry),
        # Bottom-Right corner
        (x + rx, y + ry),
        # Botton-Left corner
        (x - rx, y + ry)
    ]
end

"""
Represents a 2D circular boundary.
"""
struct Circle <: Boundary
    x::Real
    y::Real
    r::Real
end

+(c::Circle, (x, y)::Point) = Circle(c.x + x, c.y + y, c.r)
-(c::Circle, (x, y)::Point) = Circle(c.x - x, c.y - y, c.r)
*(c::Circle, n::Real) = Circle(c.x, c.y, n * c.r)
/(c::Circle, n::Real) = Circle(c.x, c.y, c.r / n)

Base.convert(::Type{Rect}, C::Circle) = Rect(C.x, C.y, C.r, C.r)

in(item::T, C::Circle) where {T} = begin
    x, y = _position(item)
    d² = distance²((x, y), (C.x, C.y))
    return d² ≤ C.r ^ 2
end

in(A::Circle, B::Circle) = begin
    d² = distance²((B.x, B.y), (A.x, A.y))
    return d² < A.r + B.r
end

in(self::Circle, range::Rect) = begin
    dx = abs(range.x - self.x)
    dy = abs(range.y - self.y)

    r = self.r
    w, h = range.w/2, range.h/2
    edges = (dx - w)^2 + (dy - h)^2

    if dx > r + w || dy > r + h return false end
    if dx <= w || dy <= h return true end;

    return edges <= r^2
end

in(R::Rect, C::Circle) = C in R

mutable struct Quadtree{T}
    datatype::Type{T}
    capacity::Int
    bounds::Rect
    items::Vector{T}
    size::Int
    sections::Vector{Quadtree{T}}
    Quadtree{T}(init::Function) where {T} = (self = new{T}(); init(self); self)
end

function Quadtree{T}(bounds::Rect, capacity::Int) where {T}
    return Quadtree{T}() do self
        self.datatype = T
        self.capacity = capacity
        self.bounds = bounds
        self.size = 0
        self.items = Vector{T}()
        self.sections = Vector{Quadtree{T}}()
    end
end

function Quadtree{T}((x, y)::Point, width::Real, height::Real, capacity::Int) where {T}
    return Quadtree{T}(Rect(x, y, width, height), capacity)
end

function Quadtree{T}(init::Function, range::AbstractRange, bounds::Rect, capacity::Int) where {T}
    qt = Quadtree{T}(bounds, capacity)

    foreach(range) do i
        push!(qt, init(i))
    end

    return qt
end

"""
        isleaf(qt::Quadtree) -> Bool

Return true if `qt` is leaf (has no children quadtree).
"""
isleaf(qt::Quadtree) = isempty(qt.sections)

"""
        insert!(qt::Quadtree{T}, item::T) -> Bool

Insert an `item` in the quadtree `qt`.

Returns true if the item was inserted successfully, false otherwise.
"""
function insert!(qt::Quadtree{T}, item::T)::Bool where {T}
    # do not add if its not
    # in the current bounds
    !(item in qt.bounds) && return false;

    if length(qt.items) < qt.capacity
        push!(qt.items, item)
        qt.size += 1
        return true;
    else
        isleaf(qt) && subdivide!(qt)
        for section in qt.sections
            if insert!(section, item) 
                qt.size += 1
                return true;
            end
        end
    end
end

"""
        subdivide!(qt::Quadtree)

Subdivides the quadtree `qt` in four sections.
"""
function subdivide!(qt::Quadtree{T}) where {T}
    w, h = qt.bounds.w, qt.bounds.h
    P = vertices(qt.bounds / 2)
    qt.sections = Quadtree{T}.(P, w/2, h/2, qt.capacity)
end

"""
        push!(qt, items...)

Inserts all `items` on `qt`.
"""
push!(qt::Quadtree{T}, items::T...) where {T} = begin
    for item in items
        insert!(qt, item)
    end
end

append!(qt::Quadtree{T}, collection::Vector{T}...) where {T} = begin
    for items in collection
        push!(qt, items...)
    end
end

"""
        length(qt::Quadtree) -> Int

Returns the number of items in `qt`.
"""
length(qt::Quadtree) = qt.size
"""
        size(qt::Quadtree) -> Int

Returns the number of items in `qt`.
"""
size(qt::Quadtree) = qt.size

"""
        query(qt::Quadtree{T}, bounds::Boundary) -> Vector{T}

Returns all items from `qt` that are in the `bounds` boundary or an empty array,
otherwise.
"""
function query(qt::Quadtree{T}, bounds::Boundary)::Vector{T} where {T}
    result = Vector{T}()

    if bounds in qt.bounds
        append!(result, filter(item -> item in bounds, qt.items))
        if !isleaf(qt)
            foreach(qt.sections) do section
                append!(result, query(section, bounds))
            end
        end
    end

    return result;
end
"""
        query!(array, quadtree, bounds)

In place version of the [query](@ref) method.
"""
query!(array::Vector{T}, qt::Quadtree{T}, range::Boundary) where {T} = empty!(array) && append!(array, query(qt, range))

"""
        search(quadtree, x, y, radius) -> Vector

Returns all items from the `quadtree` that falls on a circular boundary,
where `(x, y)` is the position of the search and `r` is the radius.
"""
function search(qt::Quadtree, x::Real, y::Real, radius::Real)
    return query(qt, Circle(x, y, radius))
end

"""
        search!(array, quadtree, x, y, radius)

In place version of the [search](@ref) method.
"""
function search!(array::Vector{T}, qt::Quadtree{T}, x::Real, y::Real, radius::Real) where {T}
    query!(array, qt, Circle(x, y, radius))
end

end # module
