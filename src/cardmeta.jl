#=
# The `cardmeta` pipeline

Cardmeta blocks add metadata to a demo file.  

The pipeline has two parts:
- The actual cardmeta block which moves things around
- The initial transformer which moves all cardmeta blocks to the end of the page

The reason we need to move the block to the end is so that it is evaluated
after all other blocks in the page.
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
        @debug "Skipping evaluation of @example block in draft mode:\n$(x.code)"
        Documenter.create_draft_result!(node; blocktype="@example")
        return
    end

    # Literate.jl uses the page filename as an "environment name" for the example block,
    # so we need to extract that from the page.  The code in the meta block has
    # to be evaluated in the same module in order to have access to local variables.
    page_name = first(splitext(last(splitdir(page.source))))
    page_link_path = first(splitext(relpath(page.build, doc.user.build)))
    @info "Running Cardmeta for $page_name"
    gallery_dict = Documenter.getplugin(doc, ExampleConfig).gallery_dict

    meta = get!(gallery_dict, page_name, Dict{Symbol, Any}())
    meta[:Path] = page_link_path
    # The sandboxed module -- either a new one or a cached one from this page.
    current_mod = Documenter.get_sandbox_module!(page.globals.meta, "atexample", page_name)

    x = node.element
    lines = Documenter.find_block_in_file(x.code, page.source)
    @debug "Evaluating @cardmeta block:\n$(x.code)"
    # @infiltrate

    for (ex, str) in Documenter.parseblock(x.code, doc, page)
        # If not `isassign`, this might be a comment, or any code that the user
        # wants to hide. We should probably warn, but it is common enough that
        # we will silently skip for now.
        if Documenter.isassign(ex)
            if !(ex.args[1] in (:Title, :Description, :Cover, :Authors, :Date, :Tags))
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

    # Title
    # If no name is given, find the first header in the page,
    # and use that as the name.
    elements = collect(page.mdast.children)
    # elements is a vector of Markdown.jl objects,
    # you can get the MarkdownAST stuff via `page.mdast`.
    # I f``
    idx = findfirst(x -> x.element isa Union{MarkdownAST.Heading, Documenter.AnchoredHeader}, elements)
    title = if isnothing(idx)
        page_name
    else
        Documenter.MDFlatten.mdflatten(elements[idx])
    end
    get!(meta, :Title, title)

    # Cover - check for e.g. `fig`, `f`, `figure`
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
            # This used to be `if contents isa Makie.FigureLike`, but that's
            # not generic.
            # So we check if the function `set_cover_to_image!` is applicable 
            # to the contents.  If it is, then we clearly have some dispatch
            # defined, meaning that the contents can be made into an image.
            # If it isn't applicable, then there is no dispatch (eg `DiffEqSolution`)
            # so we can ignore it and assume there is no cover figure.
            if applicable(set_cover_to_image!, meta, page, doc, contents) 
                meta[:Cover] = contents
                break
            end
        end
    end

    if haskey(meta, :Cover)
        # recall that `idx` is the index of the first header element.
        if !isnothing(idx)
            # insert the cover image into the page
            MarkdownAST.insert_after!(elements[idx], MarkdownAST.@ast Documenter.RawNode(:html, "<img src=\"$(Base.invokelatest(get_image_url, page, doc, meta[:Cover]))\"/>"))
        end
        # downsample the cover image for the card
        Base.invokelatest(set_cover_to_image!, meta, page, doc)
    end
 

    # Authors and Date are for the transformer and can be applied within this block, the first four 
    # params need to go to the gallery/card object though.
    # TODO: get the example config and see if Author or Date plugins are enabled, if so then
    # add the blocks here...

    node.element = Documenter.MetaNode(x, page.globals.meta)

end

# Default implementation for string covers (already a URL)
get_image_url(page, doc, s::String) = s

# Generic implementation using the new MIME-based system
function get_image_url(page, doc, content)
    # Get configuration from ExampleConfig if available
    config = get_cover_image_config(doc)
    
    # Process the cover image using the new MIME-based system
    try
        result = process_cover_image(page, doc, content, config)
        return result.relative_url
    catch e
        if e isa UnsupportedFormatError
            @warn "Unsupported content type for cover image: $(typeof(content)). Skipping cover generation."
            return nothing
        else
            rethrow(e)
        end
    end
end

function set_cover_to_image!(meta, page, doc)
    return set_cover_to_image!(meta, page, doc, meta[:Cover])
end

# String covers are already URLs, no processing needed
set_cover_to_image!(meta, page, doc, cover::String) = cover

# Generic implementation using the new MIME-based system
function set_cover_to_image!(meta, page, doc, content)
    # Get configuration from ExampleConfig if available
    config = get_cover_image_config(doc)
    
    # Process the cover image using the new MIME-based system
    try
        result = process_cover_image(page, doc, content, config)
        
        # Store the relative URL in the meta dictionary for the card
        meta[:Cover] = result.relative_url
        
        return result.relative_url
    catch e
        if e isa UnsupportedFormatError
            @warn "Unsupported content type for cover image: $(typeof(content)). Skipping cover generation."
            meta[:Cover] = nothing
            return nothing
        else
            rethrow(e)
        end
    end
end

"""
    get_cover_image_config(doc) -> CoverImageConfig

Get the CoverImageConfig from the document's ExampleConfig, or return default configuration.

This function checks if the ExampleConfig plugin has a cover_image_config field,
and returns it if available. Otherwise, it returns a default CoverImageConfig.
"""
function get_cover_image_config(doc)
    example_config = Documenter.getplugin(doc, ExampleConfig)
    
    # Check if the ExampleConfig has a cover_image_config field
    if hasfield(typeof(example_config), :cover_image_config)
        return example_config.cover_image_config
    else
        # Return default configuration
        return CoverImageConfig()
    end
end


