using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter.DOM: escapehtml
import Documenter: MarkdownAST

abstract type OverviewGalleryBlocks <: Documenter.Expanders.ExpanderPipeline end

# Order doesn't really matter, because the expansion is done based on page location first.
Documenter.Selectors.order(::Type{OverviewGalleryBlocks}) = 12.0
Documenter.Selectors.matcher(::Type{OverviewGalleryBlocks}, node, page, doc) = Documenter.iscode(node, r"^@overviewgallery")

"Build a `Card` from a gallery_dict entry (the Dict written by `@cardmeta`)."
function _card_from_entry(element)
    href  = element[:Path]                         # required (set by @cardmeta)
    cover = get(element, :Cover, _EMPTY_COVER)
    title = get(element, :Title, "")
    desc  = get(element, :Description, "")
    tags  = _normalize_tags(get(element, :Tags, String[]))
    return Card(string(title), string(desc), string(cover), string(href), tags)
end

function Documenter.Selectors.runner(::Type{OverviewGalleryBlocks}, node, page, doc)
    @assert node.element isa MarkdownAST.CodeBlock
    x = node.element
    @assert Base.contains(x.info, "@overviewgallery")
    @assert !isempty(chomp(x.code)) "The `@overviewgallery` block must have at least one page name."

    if Documenter.is_draft(doc, page)
        @debug "Skipping evaluation of @overviewgallery block in draft mode:\n$(x.code)"
        Documenter.create_draft_result!(node; blocktype = "@overviewgallery")
        return
    end

    settings = Documenter.getplugin(doc, ExampleConfig)
    gallery_dict = settings.gallery_dict

    not_found = String[]
    cards = Card[]
    for pagename in split(chomp(x.code), '\n')
        pagename = strip(pagename)
        isempty(pagename) && continue
        if !haskey(gallery_dict, pagename)
            push!(not_found, pagename)
            continue
        end
        push!(cards, _card_from_entry(gallery_dict[pagename]))
    end

    node.element = emit_gallery(settings.renderer, cards, doc, page)

    if !isempty(not_found)
        @warn "The following pages were not found in the gallery:\n$(join(not_found, "\n"))"
    end
end

# --- @autooverviewgallery ---------------------------------------------------
# Renders EVERY card in the gallery, the way `@autodocs` renders every docstring
# (vs `@docs`/`@overviewgallery`, which take an explicit list). The block body is
# ignored; ordering is deterministic — cards sort by their optional `@cardmeta`
# `Order` (ranked cards lead in ascending order, unranked follow), then gallery key.

# Sort key for a card's optional `@cardmeta` `Order`: ranked cards get `(0, order)`
# so they lead in ascending order; unranked (missing / non-`Real`) get `(1, 0.0)` so
# they follow. Ties within a group break on the gallery key at the call site.
_order_rank(order::Real) = (0, float(order))
_order_rank(::Any) = (1, 0.0)

abstract type AutoOverviewGalleryBlocks <: Documenter.Expanders.ExpanderPipeline end

Documenter.Selectors.order(::Type{AutoOverviewGalleryBlocks}) = 12.0
Documenter.Selectors.matcher(::Type{AutoOverviewGalleryBlocks}, node, page, doc) = Documenter.iscode(node, r"^@autooverviewgallery")

function Documenter.Selectors.runner(::Type{AutoOverviewGalleryBlocks}, node, page, doc)
    @assert node.element isa MarkdownAST.CodeBlock
    x = node.element
    @assert Base.contains(x.info, "@autooverviewgallery")

    if Documenter.is_draft(doc, page)
        @debug "Skipping evaluation of @autooverviewgallery block in draft mode"
        Documenter.create_draft_result!(node; blocktype = "@autooverviewgallery")
        return
    end

    settings = Documenter.getplugin(doc, ExampleConfig)
    gallery_dict = settings.gallery_dict

    # Exclude this page's own key — a gallery index page is not itself a card.
    # Order by each card's `@cardmeta` `Order` (ranked ascending, then unranked),
    # breaking ties on the gallery key.
    self_key = first(splitext(relpath(page.build, doc.user.build)))
    keys = collect(k for k in Base.keys(gallery_dict) if k != self_key)
    sort!(keys; by = k -> (_order_rank(get(gallery_dict[k], :Order, nothing)), k))
    cards = Card[_card_from_entry(gallery_dict[k]) for k in keys]

    node.element = emit_gallery(settings.renderer, cards, doc, page)
end
