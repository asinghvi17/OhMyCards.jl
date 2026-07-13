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

    # prettyurls special-cases `index.md` to `index.html` at the build root.
    html = read(joinpath(builddir, "index.html"), String)
    @test occursin("omc-gallery-search", html)         # search input rendered
    @test occursin("data-tags=\"thermal,beginner\"", html)
    @test occursin("data-tag=\"mechanical\"", html)    # tag chip from beta
    @test occursin("Alpha", html)
    @test occursin("Beta", html)
end

@testset "@autooverviewgallery renders every card" begin
    root = mktempdir()
    src = joinpath(root, "src"); mkpath(joinpath(src, "examples", "A")); mkpath(joinpath(src, "examples", "B"))
    write(joinpath(src, "examples", "A", "index.md"), """
    # Alpha
    ```@cardmeta
    Title = "Alpha"
    Tags = ["thermal"]
    ```
    """)
    write(joinpath(src, "examples", "B", "index.md"), """
    # Beta
    ```@cardmeta
    Title = "Beta"
    Tags = ["mechanical"]
    ```
    """)
    # No explicit list — the auto block lists every card itself.
    write(joinpath(src, "examples", "index.md"), """
    # Gallery

    ```@autooverviewgallery
    ```
    """)
    builddir = joinpath(root, "build")
    makedocs(; sitename = "auto", root = root, build = builddir, format = Documenter.HTML(),
             plugins = [ExampleConfig(; renderer = VitepressGallery())],
             pages = ["examples/index.md", "examples/A/index.md", "examples/B/index.md"],
             warnonly = true, remotes = nothing)
    html = read(joinpath(builddir, "examples", "index.html"), String)
    @test occursin("Alpha", html)            # both cards auto-listed
    @test occursin("Beta", html)
    @test occursin("data-tags=\"thermal\"", html)
    @test occursin("data-tags=\"mechanical\"", html)
    # The gallery index page is not itself a card (no injected @cardmeta, self-excluded).
    @test !occursin("href=\"examples/index", html)
end

@testset "pre-populated :Path survives @cardmeta (gallery href)" begin
    # The DyadDocs build stage pre-populates a card with an href RELATIVE to the
    # gallery page (e.g. "A/"); @cardmeta must not clobber it with the page link
    # path ("examples/A/index"), which would double the `examples/` prefix.
    gd = Dict{String,Any}("examples/A/index" => Dict{Symbol,Any}(:Path => "A/", :Title => "Alpha"))
    cfg = ExampleConfig(; renderer = VitepressGallery(), gallery_dict = gd)

    root = mktempdir(); src = joinpath(root, "src"); mkpath(joinpath(src, "examples", "A"))
    write(joinpath(src, "examples", "A", "index.md"), """
    # Alpha
    ```@cardmeta
    Title = "Alpha"
    ```
    """)
    # The index page is NOT in expandfirst (it carries a gallery block), so it renders
    # AFTER the demo page's @cardmeta — the exact ordering that exposed the clobber.
    write(joinpath(src, "examples", "index.md"), """
    # Gallery
    ```@autooverviewgallery
    ```
    """)
    builddir = joinpath(root, "build")
    makedocs(; sitename = "p", root = root, build = builddir, format = Documenter.HTML(),
             plugins = [cfg], pages = ["examples/index.md", "examples/A/index.md"],
             warnonly = true, remotes = nothing)
    html = read(joinpath(builddir, "examples", "index.html"), String)
    @test occursin("href=\"A/\"", html)                  # pre-populated href wins
    @test !occursin("href=\"examples/A/index", html)     # NOT clobbered by @cardmeta
end

@testset "unique gallery keys for like-named pages" begin
    root = mktempdir()
    src = joinpath(root, "src"); mkpath(joinpath(src, "examples", "A")); mkpath(joinpath(src, "examples", "B"))
    write(joinpath(src, "examples", "A", "index.md"), """
    # Alpha
    ```@cardmeta
    Title = "Alpha"
    Tags = ["x"]
    ```
    """)
    write(joinpath(src, "examples", "B", "index.md"), """
    # Beta
    ```@cardmeta
    Title = "Beta"
    Tags = ["y"]
    ```
    """)
    # Gallery lists the unique LINK-PATH keys.
    write(joinpath(src, "index.md"), """
    # Gallery
    ```@overviewgallery
    examples/A/index
    examples/B/index
    ```
    """)
    builddir = joinpath(root, "build")
    makedocs(; sitename = "k", root = root, build = builddir, format = Documenter.HTML(),
             plugins = [ExampleConfig(; renderer = VitepressGallery())],
             pages = ["index.md", "examples/A/index.md", "examples/B/index.md"], warnonly = true,
             remotes = nothing)
    html = read(joinpath(builddir, "index.html"), String)
    @test occursin("Alpha", html)            # both cards present — no "index" collision
    @test occursin("Beta", html)
    @test occursin("data-tags=\"x\"", html)
    @test occursin("data-tags=\"y\"", html)

    # Explicit Name override keys by that name.
    gd = Dict{String,Any}()
    cfg = ExampleConfig(; renderer = VitepressGallery(), gallery_dict = gd)
    root2 = mktempdir(); src2 = joinpath(root2, "src"); mkpath(src2)
    write(joinpath(src2, "page.md"), """
    # Named
    ```@cardmeta
    Name = "my-custom-key"
    Title = "Named"
    ```
    """)
    makedocs(; sitename = "k2", root = root2, build = joinpath(root2, "build"),
             format = Documenter.HTML(), plugins = [cfg], pages = ["page.md"], warnonly = true,
             remotes = nothing)
    @test haskey(gd, "my-custom-key")
    @test !haskey(gd, "page")               # NOT keyed by basename
end
