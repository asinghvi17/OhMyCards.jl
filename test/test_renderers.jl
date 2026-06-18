using OhMyCards
using OhMyCards: GalleryRenderer, Card, emit_gallery, DocumenterGallery
using Documenter
using Test

@testset "DocumenterGallery" begin
    cards = [
        Card("Coffee Mug", "Espresso cooling", "assets/icon.svg",
             "examples/CoffeeMugDemo/index", ["thermal", "beginner"]),
        Card("Thermal House", "House heating", "assets/house.svg",
             "examples/ThermalHouseDemo/index", ["thermal"]),
    ]
    el = emit_gallery(DocumenterGallery(), cards, nothing, nothing)
    @test el isa Documenter.RawNode
    @test el.name === :html
    html = el.text
    @test occursin("grid-container", html)
    @test occursin("examples/CoffeeMugDemo/index", html)   # href present
    @test occursin("Coffee Mug", html)                     # title present
    @test occursin("assets/icon.svg", html)                # cover present
    # Default renderer injects no scoped CSS:
    @test !occursin("<style scoped>", html)
end

@testset "DocumenterGallery scoped CSS" begin
    cards = [Card("A", "desc", "a.svg", "examples/A/index", String[])]
    el = emit_gallery(DocumenterGallery(; inject_scoped_css = true), cards, nothing, nothing)
    html = el.text
    @test occursin("<style scoped>", html)
    @test occursin(".img-box", html)          # a selector from gallery_style.css
    @test occursin("</style>", html)
end

@testset "ExampleConfig.renderer" begin
    @test ExampleConfig().renderer isa DocumenterGallery
    @test ExampleConfig().renderer.inject_scoped_css == false
    cfg = ExampleConfig(; renderer = DocumenterGallery(; inject_scoped_css = true))
    @test cfg.renderer.inject_scoped_css == true
    # inject_scoped_css is no longer a field of ExampleConfig:
    @test !(:inject_scoped_css in fieldnames(ExampleConfig))
end
