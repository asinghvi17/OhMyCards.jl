using OhMyCards
using OhMyCards: VitepressGallery
using Documenter
using Test

@testset "@overviewgallery build (VitepressGallery)" begin
    root = mktempdir()
    src = joinpath(root, "src")
    mkpath(src)

    # Two example pages with @cardmeta (incl. Tags) ...
    write(joinpath(src, "alpha.md"), """
    # Alpha Example

    Some prose.

    ```@cardmeta
    Title = "Alpha"
    Description = "First example"
    Tags = ["thermal", "beginner"]
    ```
    """)
    write(joinpath(src, "beta.md"), """
    # Beta Example

    More prose.

    ```@cardmeta
    Title = "Beta"
    Description = "Second example"
    Tags = ["mechanical"]
    ```
    """)
    # ... and an index page with the gallery block.
    write(joinpath(src, "index.md"), """
    # Gallery

    ```@overviewgallery
    alpha
    beta
    ```
    """)

    builddir = joinpath(root, "build")
    makedocs(;
        sitename = "OMC test",
        root = root,
        build = builddir,
        format = Documenter.HTML(),
        plugins = [ExampleConfig(; renderer = VitepressGallery())],
        pages = ["index.md", "alpha.md", "beta.md"],
        warnonly = true,
        remotes = nothing,
    )

    # Under Documenter.HTML() prettyurls, `index.md` is special-cased to emit
    # `index.html` at the build root (other page names would emit `<name>/index.html`).
    html = read(joinpath(builddir, "index.html"), String)
    @test occursin("omc-gallery-search", html)         # search input rendered
    @test occursin("data-tags=\"thermal,beginner\"", html)
    @test occursin("data-tag=\"mechanical\"", html)    # tag chip from beta
    @test occursin("Alpha", html)
    @test occursin("Beta", html)
end
