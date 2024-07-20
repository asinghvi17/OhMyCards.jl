using OhMyCards
using Documenter
using Literate
using quarto_jll

DocMeta.setdocmeta!(OhMyCards, :DocTestSetup, :(using OhMyCards); recursive=true)

# Markdownify the Literate logo example

# Literate.markdown(joinpath(@__DIR__, "logo.jl"), joinpath(@__DIR__, "src"); documenter = true)

# cp(joinpath(dirname(pathof(OhMyCards)), "gallery_style.css"), joinpath(@__DIR__, "src", "gallery_style.css"))

plugins = [ExampleConfig(; inject_scoped_css = true)]

makedocs(;
    modules=[OhMyCards],
    authors="Anshul Singhvi <anshulsinghvi@gmail.com> and contributors",
    sitename="OhMyCards.jl",
    format=Documenter.HTML(;
        canonical="https://asinghvi17.github.io/OhMyCards.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
    plugins,
    warnonly = true,
)

@show plugins[1].gallery_dict

deploydocs(;
    repo="github.com/asinghvi17/OhMyCards.jl",
    devbranch="main",
)
