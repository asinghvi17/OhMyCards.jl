#=
# The `cardmeta` pipeline

Cardmeta blocks add metadata to a demo file. The block is moved to the page end
so it evaluates after all other blocks (handled by the build-step transformer).
=#

using Documenter
using ImageTransformations, ImageIO, Base64, FileIO # for resize
import Documenter: MarkdownAST

abstract type CardMetaBlocks <: Documenter.Expanders.ExpanderPipeline end

# Order doesn't really matter, because the expansion is done based on page location first.
Documenter.Selectors.order(::Type{CardMetaBlocks}) = 12.0
Documenter.Selectors.matcher(::Type{CardMetaBlocks}, node, page, doc) = Documenter.iscode(node, r"^@cardmeta")

function Documenter.Selectors.runner(::Type{CardMetaBlocks}, node, page, doc)
    # Bail early if in draft mode
    if Documenter.is_draft(doc, page)
        @debug "Skipping evaluation of @cardmeta block in draft mode:\n$(node.element.code)"
        Documenter.create_draft_result!(node; blocktype="@example")
        return
    end

    # `page_name` names the per-page sandbox module so the meta block evaluates in
    # the same module as the example (sharing local variables); non-uniqueness
    # across pages is fine since it is stored in page.globals.meta.
    page_name = first(splitext(last(splitdir(page.source))))
    page_link_path = first(splitext(relpath(page.build, doc.user.build)))
    @info "Running Cardmeta for $page_name"
    gallery_dict = Documenter.getplugin(doc, ExampleConfig).gallery_dict

    # Sandboxed module -- new or cached for this page.
    current_mod = Documenter.get_sandbox_module!(page.globals.meta, "atexample", page_name)

    x = node.element

    # Gallery key: explicit `Name`, else the unique page LINK PATH. (A basename key
    # collided across like-named pages, e.g. every `examples/<Demo>/index.md`.)
    gallery_key = page_link_path
    for (ex, _str) in Documenter.parseblock(x.code, doc, page)
        if Documenter.isassign(ex) && ex.args[1] === :Name
            try
                gallery_key = string(Core.eval(current_mod, ex.args[2]))
            catch err
                @warn "OhMyCards: failed to evaluate `Name` in @cardmeta" exception=err
            end
            break # first Name= wins
        end
    end

    if haskey(gallery_dict, gallery_key)
        @warn "OhMyCards: gallery key $(repr(gallery_key)) already used by another page; overwriting its metadata" page = page.source
    end
    meta = get!(gallery_dict, gallery_key, Dict{Symbol, Any}())
    meta[:Path] = page_link_path
    lines = Documenter.find_block_in_file(x.code, page.source)
    @debug "Evaluating @cardmeta block:\n$(x.code)"
    # @infiltrate

    for (ex, str) in Documenter.parseblock(x.code, doc, page)
        # Non-assignments (comments, hidden code) are silently skipped for now.
        if Documenter.isassign(ex)
            if !(ex.args[1] in (:Title, :Description, :Cover, :Authors, :Date, :Tags, :Name))
                source = Documenter.locrepr(page.source, lines)
                @warn(
                    "In $source: `@cardmeta` block has an unsupported " *
                    "keyword argument: $(ex.args[1])",
                )
            end
            try
                meta[ex.args[1]] = Core.eval(current_mod, ex.args[2])
            catch err
                Documenter.@docerror(doc, :meta_block,
                    """
                    failed to evaluate `$(strip(str))` in `@cardmeta` block in $(Documenter.locrepr(page.source, lines))
                    ```$(x.info)
                    $(x.code)
                    ```
                    """, exception = err)
            end
        end
    end

    # TODO: get defaults
    # How?
    # Title: get the first heading node on the page as DocumenterVitepress does
    # Description: empty string as default
    # Cover: no image as default
    # Author: Default should be hardcoded to `["Anshul Singhvi"](https://github.com/asinghvi17)`
    # Date: nothing, don't include it if nothing

    # Title: default to the first header on the page.
    elements = collect(page.mdast.children)
    idx = findfirst(x -> x.element isa Union{MarkdownAST.Heading, Documenter.AnchoredHeader}, elements)
    title = if isnothing(idx)
        page_name
    else
        Documenter.MDFlatten.mdflatten(elements[idx])
    end
    get!(meta, :Title, title)

    # Cover - check for a figure bound to `fig`, `f`, or `figure`.
    if !haskey(meta, :Cover) # no default was assigned
        for potential_name in (:fig, :f, :figure)
            contents = nothing
            try
                _c = Core.eval(current_mod, potential_name)
                contents = _c
            catch e
                if e isa UndefVarError
                    continue
                else
                    rethrow(e)
                end
            end
            # Use it only if `set_cover_to_image!` has a dispatch for it (a generic
            # alternative to `contents isa Makie.FigureLike`); else assume no cover.
            if applicable(set_cover_to_image!, meta, page, doc, contents)
                meta[:Cover] = contents
                break
            end
        end
    end

    if haskey(meta, :Cover)
        # insert the cover image after the first header (idx)
        if !isnothing(idx)
            MarkdownAST.insert_after!(elements[idx], MarkdownAST.@ast Documenter.RawNode(:html, "<img src=\"$(Base.invokelatest(get_image_url, page, doc, meta[:Cover]))\"/>"))
        end
        # downsample the cover image for the card
        Base.invokelatest(set_cover_to_image!, meta, page, doc)
    end
 

    # TODO: if the Author/Date plugins are enabled in the example config, add those
    # blocks here (Authors/Date are for the transformer; the first four go to the card).

    node.element = Documenter.MetaNode(x, page.globals.meta)

end

get_image_url(page, doc, s::String) = s

function set_cover_to_image!(meta, page, doc)
    return set_cover_to_image!(meta, page, doc, meta[:Cover])
end

set_cover_to_image!(meta, page, doc, cover::String) = cover

# Implement the cover interface for images (`AbstractMatrix{<: Colors.Colorant}`)


