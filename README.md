# Quadtrees

Implementation of [Quadtrees](https://en.wikipedia.org/wiki/Quadtree) using the julia programming language. This package is intended to be used with the [Alexya.jl](#) package and the [Luxor.jl](#) package, but it can be used independently.

## Installation

```julia
import Pkg; Pkg.add("Quadtrees")
```

```julia
import Pkg; Pkg.add(url = "https://github.com/alexya-projects/Quadtree.git")
```

```julia-REPL
julia> ] add Quadtrees
```

```julia-REPL
julia> ] add https://github.com/alexya-projects/Quadtree.git 
```

## How to use

First, import the `Quadtrees` module:

```julia
using Quadtrees

# or

import Quadtrees: Quadtree
```

Then, define the data type you need to use with the quadtree.
Remember that your type must have a 2D position.

```julia
mutable struct Particle
    x::Real
    y::Real
    radius::Real
end
```

Before constructing the `quadtree` object, you need to define
the `Quadtrees.position` method for your type:

```julia
Quadtrees.position(p::Particle) = (p.x, p.y)
```

> The `Quadtrees.position` method is used to determine
> the position of each element in the quadtree, so it's
> important to define it, otherwise your code won't work.

Then, create your `quadtree`.

```julia
qt = Quadtree{Particle}((0, 0), 400, 400, 4)
```

The `Quadtree` constructor accept four parameters:

1. A tuple of two real numbers (x, y), that determines the `quadtree's` center position.
2. The `quadtree's` width.
3. The `quadtree's` height.
4. The `quadtree's` capacity (how many items it will have before dividing).

Then, create your objects (`Particles` in this case), and insert then in your `quadtree`.

```julia
for i in 0:999
    # two random numbers between 0 and 200
    x, y = rand(Float64, 2) * 200
    # add 1 to make sure the radius is not zero
    radius = rand(Float64) * 49 + 1
    p = Particle(x, y, radius)
    # insert the particle into the quadtree.
    insert!(qt, p)
end
```

Now you can `search` the `quadtree` for items (`Particles`, in this case), that
are located within a circular range, located at `(x, y)` with radius `r`.

For example, searching for particles within a range located at
`(5, 10)` with radius `50`:

```julia
# s for search
sx, sy = 5, 10
sr = 50
result = search(qt, sx, sy, sr)
```

The return is an array of the object type that the quadtree contains.

> Note: If no object is within the range, the result will be an empty array.

Now you can do whatever you want with the objects that the search found:

For example, i'll make each particle object 20% bigger:

```julia
for particle in result
    particle.radius += particle.radius * .20
end
```

## TODO

1. [ ] implement the `clear` method.
2. [ ] dynamic quadtree.

## License

MIT License

Copyright (c) 2021 Jorge Pereira <jorge.brito.json@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
