using Documenter

# Create a test structure
tmpdir = mktempdir()
src_dir = joinpath(tmpdir, "src")
mkpath(src_dir)
mkpath(joinpath(src_dir, "examples"))
write(joinpath(src_dir, "index.md"), "# Index\n")
write(joinpath(src_dir, "examples", "plot.md"), "# Plot Example\n")

# Test with prettyurls=false
doc_no_pretty = makedocs(
    sitename = "Test",
    source = src_dir,
    build = joinpath(tmpdir, "build_no_pretty"),
    format = Documenter.HTML(prettyurls=false, edit_link=nothing),
    debug = false,
    warnonly = true
)

page_no_pretty = doc_no_pretty.blueprint.pages["examples/plot.md"]
println("=== Without prettyurls ===")
println("page.source: ", page_no_pretty.source)
println("page.build: ", page_no_pretty.build)
println("page.workdir: ", page_no_pretty.workdir)
println("doc.user.build: ", doc_no_pretty.user.build)
println("relpath(page.workdir, doc.user.build): ", relpath(page_no_pretty.workdir, doc_no_pretty.user.build))
println()

# Test with prettyurls=true
doc_pretty = makedocs(
    sitename = "Test",
    source = src_dir,
    build = joinpath(tmpdir, "build_pretty"),
    format = Documenter.HTML(prettyurls=true, edit_link=nothing),
    debug = false,
    warnonly = true
)

page_pretty = doc_pretty.blueprint.pages["examples/plot.md"]
println("=== With prettyurls ===")
println("page.source: ", page_pretty.source)
println("page.build: ", page_pretty.build)
println("page.workdir: ", page_pretty.workdir)
println("doc.user.build: ", doc_pretty.user.build)
println("relpath(page.workdir, doc.user.build): ", relpath(page_pretty.workdir, doc_pretty.user.build))

# Clean up
rm(tmpdir, recursive=true)
