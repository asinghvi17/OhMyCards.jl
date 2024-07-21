var documenterSearchIndex = {"docs":
[{"location":"examples/manual_image/","page":"-","title":"-","text":"using Colors","category":"page"},{"location":"examples/manual_image/","page":"-","title":"-","text":"Title = \"RGB matrix cover image\"\nDescription = \"Creating an RGB matrix for a cover image\"\nCover = rand(RGB{Float32}, 100, 100)","category":"page"},{"location":"examples/plots_cover/","page":"-","title":"-","text":"using Plots","category":"page"},{"location":"examples/plots_cover/","page":"-","title":"-","text":"Cover = plot(rand(10))","category":"page"},{"location":"logo/","page":"-","title":"-","text":"EditURL = \"../logo.jl\"","category":"page"},{"location":"logo/","page":"-","title":"-","text":"In this demo, we will create the logo for this package (OhMyCards.jl) with Makie! The initial idea for the logo was to have a card with some picture or plot in the background, and indistinct title text in the foreground.","category":"page"},{"location":"logo/#Setup","page":"-","title":"Setup","text":"","category":"section"},{"location":"logo/","page":"-","title":"-","text":"<img src=\"/./LLGLUg1fdLm.png\"/>","category":"page"},{"location":"logo/","page":"-","title":"-","text":"First, we import all the packages we will need to draw the logo. We will be drawing the logo with the Makie.jl package, and using Colors.jl to get the Julia colors.  Rendering is done to a vector graphics format so we use CairoMakie as the backend.","category":"page"},{"location":"logo/","page":"-","title":"-","text":"using Makie, CairoMakie\nusing Colors\nusing MakieTeX\n\nimport Colors: JULIA_LOGO_COLORS\nJULIA_LOGO_COLORS","category":"page"},{"location":"logo/","page":"-","title":"-","text":"We want to create a rectangle with the right aspect ratio, this should do.","category":"page"},{"location":"logo/","page":"-","title":"-","text":"bounding_rectangle = Rect2f(0, 0, 15, 10)","category":"page"},{"location":"logo/","page":"-","title":"-","text":"Then, we create a geometry which is that rectangle, but with its corners rounded.","category":"page"},{"location":"logo/","page":"-","title":"-","text":"frame = Makie.roundedrectvertices(bounding_rectangle, 2, 50)\n# This function returns an unclosed vector of points (points[begin] != points[end]),\n# so we need to close it.\npush!(frame, frame[begin])\nlines(frame; color = 1:length(frame))","category":"page"},{"location":"logo/#Plotting","page":"-","title":"Plotting","text":"","category":"section"},{"location":"logo/","page":"-","title":"-","text":"Now, we can start with the plotting! First","category":"page"},{"location":"logo/","page":"-","title":"-","text":"fig = Figure(; figure_padding = 0)\nax = Axis(fig[1, 1])\nframeplot = poly!(ax, frame; color = :transparent, strokecolor = JULIA_LOGO_COLORS.purple, strokewidth = 2)\nframeplot.strokewidth = 10\nfig\n\ntitleplot = text!(ax, \"OhMyCards is AWESOME\"; color = JULIA_LOGO_COLORS.green, fontsize = 15, font = \"/Users/anshul/downloads/anquietas.ttf\")\ntitleplot.font =  \"/Users/anshul/downloads/anquietas.ttf\"\ntitleplot.fontsize = 55\ntitleplot.position = (1.5, 1.5)\nfig","category":"page"},{"location":"logo/","page":"-","title":"-","text":"Now, we sample points within the frame polygon, to get a cool background.","category":"page"},{"location":"logo/","page":"-","title":"-","text":"import GeometryOps as GO, GeoInterface as GI\nframe_poly = GI.Polygon([GI.LineString(frame)])\npoints = map(1:500) do _\n    point = Point2f(rand(0..15), rand(0..10))\n    if GO.contains(frame_poly, point)\n        return point\n    end\nend\nmagnitudes = rand(10..100, length(points))","category":"page"},{"location":"logo/","page":"-","title":"-","text":"scatter!(ax, points; color = rand(length(points)), markersize = magnitudes, colormap = :divergingbwr4095c42_n256, alpha = 0.1)","category":"page"},{"location":"logo/","page":"-","title":"-","text":"fig","category":"page"},{"location":"logo/","page":"-","title":"-","text":"hidedecorations!(ax)\nhidespines!(ax)\ntightlimits!(ax)\n\ntitleplot[1][] = \"🄾🅷 🄼🆈 🅲🅰🆁🅳🆂\"\ntitleplot[1][] = \"Ⓞⓗ Ⓜⓨ ⓒⓐⓡⓓⓢ\"\ntitleplot[1][] = \"□□ □□ □□□□□\"\nax.scene.plots[end].alpha[] = 0.2\ntranslate!(titleplot, 0, 0, 1)\nfig","category":"page"},{"location":"logo/","page":"-","title":"-","text":"ax.backgroundcolor = :transparent\nfig.scene.backgroundcolor[] = RGBAf(1,1,1,0)\nfig","category":"page"},{"location":"logo/","page":"-","title":"-","text":"","category":"page"},{"location":"logo/","page":"-","title":"-","text":"This page was generated using Literate.jl.","category":"page"},{"location":"logo/","page":"-","title":"-","text":"Title = \"OhMyCards logo\"\nDescription = \"Making a logo with Makie.jl\"\nCover = fig","category":"page"},{"location":"","page":"Home","title":"Home","text":"CurrentModule = OhMyCards","category":"page"},{"location":"#OhMyCards","page":"Home","title":"OhMyCards","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for OhMyCards.","category":"page"},{"location":"","page":"Home","title":"Home","text":"<div class=\"grid-container\">\n<div class=\"grid-item\">\n    <div class=\"gallery-image\">\n        <div class=\"img-box\">\n            <a href=\"logo\">\n                <img src=\"/./EU3kM0dbARw.png\" height=\"150px\" alt=\"logo\"/>\n                <div class=\"transparent-box1\">\n                    <div class=\"caption\">\n                        <h2>OhMyCards logo</h2>\n                    </div>\n                </div>\n                <div class=\"transparent-box2\">\n                    <div class=\"subcaption\">\n                        <p class=\"opacity-low\">Making a logo with Makie.jl</p>\n                    </div>\n                </div>\n            </a>\n        </div>\n    </div>\n</div>\n\n<style scoped>.gallery-image .heading {\n    text-align: center;\n    font-size: 2em;\n    letter-spacing: 1px;\n    padding: 40px;\n    color: black;\n}\n\n.gallery-image {\n    padding: 20px;\n    display: flex;\n    flex-wrap: wrap;\n    justify-content: center;\n}\n\n.gallery-image :deep(img) {\n    height: 260px;\n    width: 300px;\n    transform: scale(1);\n    transition: transform 0.4s ease;\n}\n\n\n.img-box {\n    box-sizing: content-box;\n    border-radius: 14px;\n    margin: 5px;\n    height: 225px;\n    width: 300px;\n    overflow: hidden;\n    display: inline-block;\n    color: white;\n    position: relative;\n    background-color: white;\n    border: 2px solid var(--vp-c-bg-alt, #f6f6f7);\n}\n\n.img-box h2 {\n    border-top: 0;\n}\n\n.img-box img {\n    height: 200px;\n    width: 300px;\n    object-fit: contain;\n    transition: transform 0.3s ease;\n    top: 0px;\n}\n\n.caption {\n    position: relative;\n    top: -60px;\n    color: black;\n    left: 10px;\n    opacity: 1;\n    transition: transform 0.3s ease;\n}\n\n.subcaption {\n    position: absolute;\n    bottom: 5px;\n    color: gray;\n    left: 10px;\n    opacity: 0;\n    transition: transform 0.3s ease;\n}\n\n.transparent-box1 {\n    height: 225px;\n    width: 300px;\n    background-color: transparent;\n    position: absolute;\n    top: 0;\n    left: 0;\n    opacity: 0.9;\n    transition: background-color 0.3s ease;\n}\n\n.transparent-box2 {\n    /* height: 100px; */\n    /* width: 250px; */\n    background-color: transparent;\n    /* position: absolute; */\n    /* top: 150px; */\n    left: 0;\n    opacity: 0.9;\n    transition: background-color 0.3s ease;\n}\n\n.img-box:hover img {\n    transform: scale(1.1);\n}\n\n.img-box:hover .transparent-box1 {\n    background-color: var(--vp-c-bg-alt, #f6f6f7);\n}\n\n.img-box:hover .transparent-box2 {\n    background-color: var(--vp-c-bg-alt, #f6f6f7);\n}\n\n.img-box:hover .caption {\n    /* transform: translateY(-20px); */\n    opacity: 1;\n}\n\n.img-box:hover .subcaption {\n    transform: translateY(-20px);\n    opacity: 1;\n}\n\n.img-box:hover {\n    border: 2px solid var(--vp-c-brand-light, #3dd027);\n    cursor: pointer;\n}\n\n.caption>p:nth-child(2) {\n    font-size: 0.8em;\n}\n.subcaption>p:nth-child(2) {\n    font-size: 0.8em;\n}\n\n.opacity-low {\n    opacity: 0.85;\n}\n\n</style>\n</div>\n","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [OhMyCards]","category":"page"},{"location":"#OhMyCards.ExampleProcessing","page":"Home","title":"OhMyCards.ExampleProcessing","text":"ExampleProcessing <: Documenter.Builder.DocumenterPipeline\n\nWhat does this do?\n\nMoves Cardmeta blocks\nAdds a quick example block (in Vitepress syntax) if requested in the pipeline and a cardmeta block is found\nAdds badges to the page if necessary\nAdds the page to expandfirst if it is not already there\n\nThis is run at priority 1.2, meaning after doctest and before expand_templates.\n\n\n\n\n\n","category":"type"}]
}
