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
