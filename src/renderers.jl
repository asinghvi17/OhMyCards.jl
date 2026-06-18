import Documenter.DOM: escapehtml

"""
    GalleryRenderer

Strategy object that turns a `Vector{Card}` into the markup replacing an
`@overviewgallery` block. Subtypes implement
[`emit_gallery`](@ref). Two ship with OhMyCards: [`DocumenterGallery`](@ref)
(static grid, default) and [`VitepressGallery`](@ref) (adds client-side search).
"""
abstract type GalleryRenderer end

"""
    Card(title, description, cover, href, tags)

Normalized gallery entry handed to a renderer. `cover` is an already-resolved
image URL or data-uri; `href` is the page link path; `tags` is a (possibly empty)
list of strings.
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

Return the element that replaces an `@overviewgallery` code block. `doc` and
`page` are the Documenter document and page; renderers must not require them to be
non-`nothing` for markup generation (so they remain unit-testable).
"""
function emit_gallery end

# Default cover used by the @overviewgallery runner (Task 1.5) when a card has no `:Cover`.
const _EMPTY_COVER =
    "data:image/svg+xml;charset=utf-8,<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"1\" height=\"1\"/>"

"""
    DocumenterGallery(; inject_scoped_css = false)

Static HTML card grid (the original OhMyCards output). With `inject_scoped_css`,
appends `gallery_style.css` as a `<style scoped>` block. No search. Works under a
plain `Documenter.HTML()` build. This is the default renderer.
"""
Base.@kwdef struct DocumenterGallery <: GalleryRenderer
    inject_scoped_css::Bool = false
end

function _documenter_card_html(card::Card)
    return """
    <div class="grid-item">
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
    entries = map(_documenter_card_html, cards)
    main_str = """
    <div class="grid-container">
    $(join(entries, "\n"))
    </div>
    """
    if r.inject_scoped_css
        scoped_css = "\n<style scoped>" *
            read(joinpath(@__DIR__, "gallery_style.css"), String) * "\n</style>"
        # Insert the <style> block just before the container's closing </div>. The
        # template ends with a trailing newline, so the last split element is empty and
        # `length(lines) - 1` targets the line holding `</div>`.
        lines = split(main_str, "\n")
        insert!(lines, length(lines) - 1, scoped_css)
        main_str = join(lines, "\n")
    end
    return Documenter.RawNode(:html, main_str)
end

"""
    VitepressGallery(; search = true, tag_filter = true)

Card grid where every card carries `data-title` / `data-description` / `data-tags`,
plus an optional search `<input>` and clickable tag-filter chips. Filtering is plain
client-side JS over the rendered cards (shipped inline as `<style>`/`<script>` via the
same `RawNode(:html, …)` mechanism `DocumenterGallery` uses for scoped CSS). This works
offline and complements Vitepress's built-in site search. Used by DyadDocs.
"""
Base.@kwdef struct VitepressGallery <: GalleryRenderer
    search::Bool = true
    tag_filter::Bool = true
end

function _vitepress_card_html(card::Card)
    return """
    <div class="grid-item" data-title="$(escapehtml(card.title))" data-description="$(escapehtml(card.description))" data-tags="$(escapehtml(join(card.tags, ",")))">
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

function emit_gallery(r::VitepressGallery, cards::Vector{Card}, doc, page)
    entries = map(_vitepress_card_html, cards)

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
    js = read(joinpath(@__DIR__, "gallery_search.js"), String)

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
    <script data-omc-gallery>
    $(js)
    </script>
    </div>
    """
    return Documenter.RawNode(:html, main_str)
end
