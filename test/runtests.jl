using OhMyCards
using Test
using Documenter
# @testset "OhMyCards.jl" begin
    # Write your tests here.
doc = makedocs(;
    debug = true,
    root = @__DIR__,
    source = "simpledoc",
    sitename = "OhMyCards",
    pages = [
        "Home" => "index.md",
        "Makie" => "examples/makie.md",
    ],
    format = Documenter.HTML(;
        canonical = "https://asinghvi17.github.io/OhMyCards.jl",
        assets = String[],
    ),
    warnonly = true,
    pagesonly = true,
    plugins = [OhMyCards.ExampleConfig(),],
);

    plots_doc = makedocs(;
        debug = true,
        sitename = "OhMyCards",
        pages = [
            "Home" => "index.md",
            "Plots" => "plots.md",
        ],
        format = Documenter.HTML(;
            canonical = "https://asinghvi17.github.io/OhMyCards.jl",
            assets = String[],
        ),
        warnonly = true,
        pagesonly = true,
    )

    colors_doc = makedocs(;
        debug = true,
        sitename = "OhMyCards",
        pages = [
            "Home" => "index.md",
            "Colors" => "colors.md",
        ],
        format = Documenter.HTML(;
            canonical = "https://asinghvi17.github.io/OhMyCards.jl",
            assets = String[],
        ),
        warnonly = true,
        pagesonly = true,
    )
# end
