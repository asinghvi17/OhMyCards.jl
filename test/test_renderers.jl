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

@testset "VitepressGallery" begin
    using OhMyCards: VitepressGallery
    cards = [
        Card("Coffee Mug", "Espresso cooling", "assets/icon.svg",
             "examples/CoffeeMugDemo/index", ["thermal", "beginner"]),
        Card("Driveline", "Powertrain", "assets/dl.svg",
             "examples/DrivelineDemo/index", ["mechanical", "thermal"]),
    ]
    el = emit_gallery(VitepressGallery(), cards, nothing, nothing)
    @test el isa Documenter.RawNode
    html = el.text
    # cards carry filter metadata
    @test occursin("data-tags=\"thermal,beginner\"", html)
    @test occursin("data-title=", html)
    @test occursin("data-description=", html)
    # search input present
    @test occursin("<input", html)
    @test occursin("omc-gallery-search", html)
    # tag chips: union of tags, deduped + sorted
    @test occursin("data-tag=\"mechanical\"", html)
    @test occursin("data-tag=\"thermal\"", html)
    # scoped CSS inlined; root + empty-state present for the filter script to target
    @test occursin("<style", html)
    @test occursin("omc-gallery-root", html)
    @test occursin("omc-gallery-empty", html)
    # filtering JS NOT inlined (Vitepress escapes/never runs body <script>s)
    @test !occursin("<script", html)

    # search/tag_filter can be disabled
    el2 = emit_gallery(VitepressGallery(; search = false, tag_filter = false), cards, nothing, nothing)
    html2 = el2.text
    @test !occursin("<input", html2)
    @test !occursin("data-tag=\"thermal\"", html2)   # no chips
    @test occursin("data-tags=", html2)              # cards still carry tags
    @test !occursin("<script", html2)                # JS never inlined
    @test occursin("<style", html2)
end

@testset "Vitepress JS delivery helpers" begin
    using OhMyCards: _gallery_assets_dir, _inject_gallery_head_script, GALLERY_SCRIPT_NAME
    # the shipped asset exists and is the file the head script references
    @test isfile(joinpath(_gallery_assets_dir(), GALLERY_SCRIPT_NAME))
    # config injection adds a base-aware <head> script entry, once, after `head: [`
    cfg = "export default defineConfig({\n  head: [\n    ['link', {}],\n  ],\n})"
    out = _inject_gallery_head_script(cfg)
    @test occursin(GALLERY_SCRIPT_NAME, out)
    @test occursin("baseTemp.base", out)
    @test count(GALLERY_SCRIPT_NAME, out) == 1
    # idempotent
    @test _inject_gallery_head_script(out) == out
end

@testset "_normalize_tags" begin
    using OhMyCards: _normalize_tags
    @test _normalize_tags("single") == ["single"]
    @test _normalize_tags(nothing) == String[]
    @test _normalize_tags(["a", "b"]) == ["a", "b"]
    @test _normalize_tags((:a, :b)) == ["a", "b"]        # Tuple of Symbols
    @test _normalize_tags([:a, :b]) == ["a", "b"]        # Vector of Symbols
    @test eltype(_normalize_tags([:a, :b])) == String    # always String elements
end
