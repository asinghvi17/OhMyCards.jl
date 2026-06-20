import Documenter.DOM: escapehtml

"""
    GalleryRenderer

Strategy turning a `Vector{Card}` into the markup that replaces an
`@overviewgallery` block; subtypes implement [`emit_gallery`](@ref). Shipped:
[`DocumenterGallery`](@ref) (static grid, default) and [`VitepressGallery`](@ref)
(adds client-side search).
"""
abstract type GalleryRenderer end

"""
    Card(title, description, cover, href, tags)

Normalized gallery entry handed to a renderer. `cover` is a resolved image URL or
data-uri; `href` is the page link path; `tags` may be empty.
"""
struct Card
    title::String
    description::String
    cover::String
    href::String
    tags::Vector{String}
end

"""
    emit_gallery(r::GalleryRenderer, cards::Vector{Card}, doc, page) -> MarkdownAST.AbstractElement

Return the element that replaces an `@overviewgallery` block. Must tolerate
`nothing` for `doc`/`page` so renderers stay unit-testable.
"""
function emit_gallery end

# Default cover when a card has no `:Cover`.
const _EMPTY_COVER =
    "data:image/svg+xml;charset=utf-8,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"/>"

"""
    DocumenterGallery(; inject_scoped_css = false)

Default renderer: static HTML card grid, no search, works under a plain
`Documenter.HTML()` build. `inject_scoped_css` appends `gallery_style.css` as a
`<style scoped>` block.
"""
Base.@kwdef struct DocumenterGallery <: GalleryRenderer
    inject_scoped_css::Bool = false
end

# Shared card markup. `data_attrs` adds the `data-title`/`-description`/`-tags`
# hooks the VitepressGallery filter JS reads; DocumenterGallery omits them.
function _card_html(card::Card; data_attrs::Bool = false)
    attrs = data_attrs ?
        " data-title=\"$(escapehtml(card.title))\" data-description=\"$(escapehtml(card.description))\" data-tags=\"$(escapehtml(join(card.tags, ",")))\"" :
        ""
    return """
    <div class="grid-item"$attrs>
        <div class="gallery-image">
            <div class="img-box">
                <a href="$(escapehtml(card.href))">
                    <img src="$(card.cover)" height="150px" alt="$(escapehtml(card.title))"/>
                    <div class="transparent-box1">
                        <div class="caption">
                            <h2>$(escapehtml(card.title))</h2>
                        </div>
                    </div>
                    <div class="transparent-box2">
                        <div class="subcaption">
                            <p class="opacity-low">$(escapehtml(card.description))</p>
                        </div>
                    </div>
                </a>
            </div>
        </div>
    </div>"""
end

function emit_gallery(r::DocumenterGallery, cards::Vector{Card}, doc, page)
    entries = map(_card_html, cards)
    main_str = """
    <div class="grid-container">
    $(join(entries, "\n"))
    </div>
    """
    if r.inject_scoped_css
        scoped_css = "\n<style scoped>" *
            read(joinpath(@__DIR__, "gallery_style.css"), String) * "\n</style>"
        # Insert <style> before the closing </div>; trailing newline makes the last
        # split element empty, so `length(lines) - 1` is the `</div>` line.
        lines = split(main_str, "\n")
        insert!(lines, length(lines) - 1, scoped_css)
        main_str = join(lines, "\n")
    end
    return Documenter.RawNode(:html, main_str)
end

"""
    VitepressGallery(; search = true, tag_filter = true)

Card grid with `data-title`/`data-description`/`data-tags` per card, plus an
optional search `<input>` and tag-filter chips. Scoped CSS is inlined, but the
filtering JS is NOT: Vitepress renders markdown through Vue, which escapes and
never runs body `<script>`s, so the JS is delivered as a `public/` asset + `<head>`
script via the `OhMyCardsDocumenterVitepressExt` extension.
"""
Base.@kwdef struct VitepressGallery <: GalleryRenderer
    search::Bool = true
    tag_filter::Bool = true
end

function emit_gallery(r::VitepressGallery, cards::Vector{Card}, doc, page)
    entries = map(c -> _card_html(c; data_attrs = true), cards)

    controls = IOBuffer()
    if r.search || r.tag_filter
        println(controls, "<div class=\"omc-gallery-controls\">")
        if r.search
            println(controls,
                "<input class=\"omc-gallery-search\" type=\"search\" placeholder=\"Search examples…\" aria-label=\"Search examples\"/>")
        end
        if r.tag_filter
            all_tags = sort(unique(reduce(vcat, [c.tags for c in cards]; init = String[])))
            println(controls, "<div class=\"omc-gallery-tags\">")
            for tag in all_tags
                println(controls,
                    "<button type=\"button\" class=\"omc-tag-chip\" data-tag=\"$(escapehtml(tag))\" aria-pressed=\"false\">$(escapehtml(tag))</button>")
            end
            println(controls, "</div>")
        end
        println(controls, "</div>")
    end

    css = read(joinpath(@__DIR__, "gallery_search.css"), String)

    # Filtering JS is NOT inlined: Vitepress escapes/never runs body `<script>`s.
    # It ships via OhMyCardsDocumenterVitepressExt; `<style>` is safe to inline.
    main_str = """
    <div class="omc-gallery-root">
    <style scoped>
    $(css)
    </style>
    $(String(take!(controls)))
    <div class="grid-container">
    $(join(entries, "\n"))
    </div>
    <div class="omc-gallery-empty">No examples match your filters.</div>
    </div>
    """
    return Documenter.RawNode(:html, main_str)
end

# Tags may arrive as Vector{String}, a Tuple, a single String, or Symbols.
_normalize_tags(t::AbstractString) = [String(t)]
_normalize_tags(t) = String[string(x) for x in t]
_normalize_tags(::Nothing) = String[]

# --- Vitepress JS delivery -------------------------------------------------
# Helpers consumed by OhMyCardsDocumenterVitepressExt to ship the filtering JS as
# a `public/` asset + `<head>` script (it can't be inlined into page content).

"Filename of the gallery search script as served from the Vitepress site root."
const GALLERY_SCRIPT_NAME = "omc_gallery_search.js"

"""
    _gallery_assets_dir() -> String

Absolute path to the dir DocumenterVitepress copies into Vitepress `public/`;
contains the gallery client assets.
"""
_gallery_assets_dir() = abspath(joinpath(@__DIR__, "..", "assets"))

"""
    _inject_gallery_head_script(config::AbstractString) -> String

Insert a base-aware `<head>` `<script src>` entry for the gallery script into a
Vitepress `config.mts` source string. Idempotent.
"""
function _inject_gallery_head_script(config::AbstractString)
    occursin(GALLERY_SCRIPT_NAME, config) && return config
    # `baseTemp.base` is in scope in the generated head array; reuse it so the
    # asset URL respects a deployed base.
    entry = "\n    ['script', { src: `\${baseTemp.base}$(GALLERY_SCRIPT_NAME)` }],"
    return replace(config, r"head:\s*\[" => m -> m * entry; count = 1)
end
