```@meta
EditURL = "../logo.jl"
```

# OhMyCards logo
```@cardmeta
Title = "OhMyCards logo"
Description = "Making a logo with Makie.jl"
Cover = fig
```
In this demo, we will create the logo for this package (OhMyCards.jl) with Makie!
The initial idea for the logo was to have a card with some picture or plot in the
background, and indistinct title text in the foreground.

## Setup
First, we import all the packages we will need to draw the logo.
We will be drawing the logo with the [Makie.jl](https://github.com/MakieOrg/Makie.jl) package,
and using Colors.jl to get the Julia colors.  Rendering is done
to a vector graphics format so we use CairoMakie as the backend.

````@example logo
using Makie, CairoMakie
using Colors
using MakieTeX

import Colors: JULIA_LOGO_COLORS
JULIA_LOGO_COLORS
````

We want to create a rectangle with the right aspect ratio, this should do.

````@example logo
bounding_rectangle = Rect2f(0, 0, 15, 10)
````

Then, we create a geometry which is that rectangle, but with its corners rounded.

````@example logo
frame = Makie.roundedrectvertices(bounding_rectangle, 2, 50)
# This function returns an unclosed vector of points (points[begin] != points[end]),
# so we need to close it.
push!(frame, frame[begin])
lines(frame; color = 1:length(frame))
````

## Plotting
Now, we can start with the plotting!
First

````@example logo
fig = Figure(; figure_padding = 0)
ax = Axis(fig[1, 1])
frameplot = poly!(ax, frame; color = :transparent, strokecolor = JULIA_LOGO_COLORS.purple, strokewidth = 2)
frameplot.strokewidth = 10
fig

titleplot = text!(ax, "OhMyCards is AWESOME"; color = JULIA_LOGO_COLORS.green, fontsize = 15, font = "/Users/anshul/downloads/anquietas.ttf")
titleplot.font =  "/Users/anshul/downloads/anquietas.ttf"
titleplot.fontsize = 55
titleplot.position = (1.5, 1.5)
fig
````

Now, we sample points within the frame polygon, to get a cool background.

````@example logo
import GeometryOps as GO, GeoInterface as GI
frame_poly = GI.Polygon([GI.LineString(frame)])
points = map(1:500) do _
    point = Point2f(rand(0..15), rand(0..10))
    if GO.contains(frame_poly, point)
        return point
    end
end
magnitudes = rand(10..100, length(points))
````

scatter!(ax, points; color = rand(length(points)), markersize = magnitudes, colormap = :diverging_bwr_40_95_c42_n256, alpha = 0.1)

````@example logo
fig
````

````@example logo
hidedecorations!(ax)
hidespines!(ax)
tightlimits!(ax)

titleplot[1][] = "🄾🅷 🄼🆈 🅲🅰🆁🅳🆂"
titleplot[1][] = "Ⓞⓗ Ⓜⓨ ⓒⓐⓡⓓⓢ"
titleplot[1][] = "□□ □□ □□□□□"
ax.scene.plots[end].alpha[] = 0.2
translate!(titleplot, 0, 0, 1)
fig
````

````@example logo
ax.backgroundcolor = :transparent
fig.scene.backgroundcolor[] = RGBAf(1,1,1,0)
fig
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

