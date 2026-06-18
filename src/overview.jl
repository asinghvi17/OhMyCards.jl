using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter.DOM: escapehtml
import Documenter: MarkdownAST

abstract type OverviewGalleryBlocks <: Documenter.Expanders.ExpanderPipeline end

# Order doesn't really matter, because the expansion is done based on page location first.
Documenter.Selectors.order(::Type{OverviewGalleryBlocks}) = 12.0
Documenter.Selectors.matcher(::Type{OverviewGalleryBlocks}, node, page, doc) = Documenter.iscode(node, r"^@overviewgallery")

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
        element = gallery_dict[pagename]
        href    = element[:Path]                       # required (set by @cardmeta)
        cover   = get(element, :Cover, _EMPTY_COVER)
        title   = get(element, :Title, "")
        desc    = get(element, :Description, "")
        tags    = _normalize_tags(get(element, :Tags, String[]))
        push!(cards, Card(string(title), string(desc), string(cover), string(href), tags))
    end

    node.element = emit_gallery(settings.renderer, cards, doc, page)

    if !isempty(not_found)
        @warn "The following pages were not found in the gallery:\n$(join(not_found, "\n"))"
    end
end