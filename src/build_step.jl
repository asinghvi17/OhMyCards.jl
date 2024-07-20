"""
    ExampleProcessing <: Documenter.Builder.DocumenterPipeline

What does this do?

- Moves Cardmeta blocks
- Adds a quick example block (in Vitepress syntax) if requested in the pipeline and a cardmeta block is found
- Adds badges to the page if necessary
- Adds the page to `expandfirst` if it is not already there

This is run at priority 1.2, meaning after `doctest` and before `expand_templates`.
"""
abstract type ExampleProcessing <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{ExampleProcessing}) = 1.2 # after doctest, before expand templates.

function _is_cardmeta_block(x)
    return x.element isa MarkdownAST.CodeBlock && Base.occursin("@cardmeta", x.element.info)
end

function Documenter.Selectors.runner(::Type{ExampleProcessing}, doc::Documenter.Document)
    settings = Documenter.getplugin(doc, ExampleConfig)
    # Iterate over all pages in the document, and check which ones have a cardmeta.
    for (filename, page) in doc.blueprint.pages
        # First, collect all cardmeta blocks on the page.  If this collection
        # is empty, then we know no cardmeta blocks exist.
        cardmeta_blocks = filter(_is_cardmeta_block, collect(page.mdast.children))
        # Now, check if the page is an example page.  The criteria here are:
        # 1. Does the page have a cardmeta block
        has_cardmeta_blocks   = !isempty(cardmeta_blocks)
        # 2. Is the page in the list of known example pages?
        is_known_example_page = Base.occursin("examples", splitdir(page.build)[1]) || page.build in settings.known_examples
        # Either of these two conditions is sufficient for our purpose.
        is_example_page = is_known_example_page | has_cardmeta_blocks
        is_example_page || continue # skip the next steps if this is not an example page
        # Now, shift the cardmeta block, or generate it if the page is an example but 
        # there is no cardmeta block.
        if has_cardmeta_blocks # some cardmeta block was detected
            # Move the cardmeta block from wherever it is to the end of the page.
            MarkdownAST.insert_after!(last(page.mdast.children), first(cardmeta_blocks))
        elseif is_known_example_page # only inject cardmeta if in examples dir
            # Inject an empty cardmeta block at the end of the page
            MarkdownAST.insert_after!(last(page.mdast.children), MarkdownAST.@ast MarkdownAST.CodeBlock("@cardmeta", ""))
        end
        # Add the page to expandfirst if it is not already there.
        # This ensures that the cardmeta blocks are all evaluated
        # before we reach an overviewgallery block.
        if is_example_page # this is technically redundant, but makes it explicitly clear
            if !(filename in doc.user.expandfirst)
                push!(doc.user.expandfirst, filename)
            end
        end
        #=
            # Now, we indulge in a bit of cheeky eval'ing.
            # If there is no title, we can actually generate one if 
            # the cardmeta block has a title key.
            # This has to be done in the build step, since
            # TrackHeaders is the first example block that is run (so that
            # the table of references is populated for `@ref`) and so
            # we need to make sure that the title is injected before
            # TrackHeaders runs.
            ex_strs = Documenter.parseblock(x.code, doc, page)
            filter!(ex_strs) do (ex, str)
                Documenter.isassign(ex) && 
                ex.args[1] in (:Title, :title) &&
                ex.args[2] isa String # interpolation makes this a QuoteNode
            end
            if !isempty(ex_strs)
                _, title_str = first(ex_strs)
                # inject the heading as the first element in the Markdown tree
                MarkdownAST.insert_before!(first(page.mdast.children), @ast MarkdownAST.Heading(1) do; title_str; end)
            end
        =#
    end
end
