"""
    ExampleProcessing <: Documenter.Builder.DocumenterPipeline

Per-page prep, run at priority 1.2 (after `doctest`, before `expand_templates`):
moves cardmeta blocks to page end, generates one for example pages that lack it,
and adds example pages to `expandfirst`.
"""
abstract type ExampleProcessing <: Documenter.Builder.DocumentPipeline end

Documenter.Selectors.order(::Type{ExampleProcessing}) = 1.2 # after doctest, before expand templates.

function _is_cardmeta_block(x)
    return x.element isa MarkdownAST.CodeBlock && Base.occursin("@cardmeta", x.element.info)
end

function Documenter.Selectors.runner(::Type{ExampleProcessing}, doc::Documenter.Document)
    settings = Documenter.getplugin(doc, ExampleConfig)
    for (filename, page) in doc.blueprint.pages
        cardmeta_blocks = filter(_is_cardmeta_block, collect(page.mdast.children))
        # A page is an example page if it has a cardmeta block or lives under examples/.
        has_cardmeta_blocks   = !isempty(cardmeta_blocks)
        is_known_example_page = Base.occursin("examples", splitdir(page.build)[1]) || page.build in settings.known_examples
        is_example_page = is_known_example_page | has_cardmeta_blocks
        is_example_page || continue
        if has_cardmeta_blocks
            # Move the cardmeta block to page end. Guard: if it is already last,
            # insert_after! would unlink! then re-insert it, corrupting the tree
            # and silently dropping the block.
            if first(cardmeta_blocks) !== last(page.mdast.children)
                MarkdownAST.insert_after!(last(page.mdast.children), first(cardmeta_blocks))
            end
        elseif is_known_example_page # inject an empty cardmeta block at page end
            MarkdownAST.insert_after!(last(page.mdast.children), MarkdownAST.@ast MarkdownAST.CodeBlock("@cardmeta", ""))
        end
        # expandfirst so cardmeta blocks are evaluated before any overviewgallery.
        if is_example_page
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
