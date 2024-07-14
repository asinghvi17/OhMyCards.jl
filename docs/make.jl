using OhMyCards
using Documenter

DocMeta.setdocmeta!(OhMyCards, :DocTestSetup, :(using OhMyCards); recursive=true)

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
)

deploydocs(;
    repo="github.com/asinghvi17/OhMyCards.jl",
    devbranch="main",
)
