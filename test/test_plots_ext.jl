# Tests for Plots extension with new MIME-based system

using Test
using OhMyCards
using Plots
using Documenter

@testset "Plots Extension - MIME-based Conversion" begin
    @testset "convert_to_format - PNG format" begin
        # Create a simple plot
        p = plot(1:10, sin.(1:10), title="Test Plot", label="sin(x)")
        
        # Test PNG conversion
        config = CoverImageConfig(target_height=600, preferred_format="png")
        bytes = OhMyCards.convert_to_format(p, MIME"image/png"(), config)
        
        # Verify we got bytes back
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
        
        # Verify it's a valid PNG (starts with PNG magic bytes)
        @test bytes[1:4] == UInt8[0x89, 0x50, 0x4e, 0x47]
    end
    
    @testset "convert_to_format - SVG format" begin
        # Create a simple plot
        p = plot(1:10, cos.(1:10), title="Test Plot", label="cos(x)")
        
        # Test SVG conversion
        config = CoverImageConfig(target_height=600, preferred_format="svg")
        bytes = OhMyCards.convert_to_format(p, MIME"image/svg+xml"(), config)
        
        # Verify we got bytes back
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
        
        # Verify it's valid SVG (contains SVG tags)
        svg_string = String(bytes)
        @test occursin("<svg", svg_string)
        @test occursin("</svg>", svg_string)
    end
    
    @testset "convert_to_format - Multiple formats" begin
        # Create a simple plot
        p = plot(1:10, exp.(1:10), title="Test Plot", label="exp(x)")
        
        # Test that we can convert to different formats
        config_png = CoverImageConfig(target_height=600, preferred_format="png")
        bytes_png = OhMyCards.convert_to_format(p, MIME"image/png"(), config_png)
        @test bytes_png isa Vector{UInt8}
        @test length(bytes_png) > 0
        
        config_svg = CoverImageConfig(target_height=600, preferred_format="svg")
        bytes_svg = OhMyCards.convert_to_format(p, MIME"image/svg+xml"(), config_svg)
        @test bytes_svg isa Vector{UInt8}
        @test length(bytes_svg) > 0
        
        # SVG and PNG should produce different outputs
        @test bytes_png != bytes_svg
    end
end

@testset "Plots Extension - Backward Compatibility" begin
    @testset "get_image_url compatibility" begin
        mktempdir() do tmpdir
            # Create mock page and doc objects
            src_dir = joinpath(tmpdir, "src")
            build_dir = joinpath(tmpdir, "build")
            mkpath(src_dir)
            mkpath(build_dir)
            
            # Create a simple documentation structure
            write(joinpath(src_dir, "index.md"), "# Test\n")
            
            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=build_dir,
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                pages=["Home" => "index.md"],
                debug=true,
                warnonly=true,
            )
            
            # Get the page object - access via the pages array
            page = first(values(doc.blueprint.pages))
            
            # Create a plot
            p = plot(1:10, sin.(1:10))
            
            # Call get_image_url
            url = OhMyCards.get_image_url(page, doc, p)
            
            # Verify URL format
            @test url isa String
            @test startswith(url, "/")
            @test endswith(url, ".png")
            
            # Verify file was created
            # Extract filename from URL (remove leading /)
            filename = url[2:end]
            filepath = joinpath(build_dir, filename)
            @test isfile(filepath)
        end
    end
    
    @testset "set_cover_to_image! compatibility" begin
        mktempdir() do tmpdir
            # Create mock page and doc objects
            src_dir = joinpath(tmpdir, "src")
            build_dir = joinpath(tmpdir, "build")
            mkpath(src_dir)
            mkpath(build_dir)
            
            # Create a simple documentation structure
            write(joinpath(src_dir, "index.md"), "# Test\n")
            
            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=build_dir,
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                pages=["Home" => "index.md"],
                debug=true,
                warnonly=true,
            )
            
            # Get the page object - access via the pages array
            page = first(values(doc.blueprint.pages))
            
            # Create a plot
            p = plot(1:10, cos.(1:10))
            
            # Create meta dictionary
            meta = Dict{Symbol, Any}()
            
            # Call set_cover_to_image!
            OhMyCards.set_cover_to_image!(meta, page, doc, p)
            
            # Verify meta was updated
            @test haskey(meta, :Cover)
            @test meta[:Cover] isa String
            @test startswith(meta[:Cover], "/")
            @test endswith(meta[:Cover], ".png")
            
            # Verify file was created
            filename = meta[:Cover][2:end]
            filepath = joinpath(build_dir, filename)
            @test isfile(filepath)
        end
    end
end

@testset "Plots Extension - Full End-to-End Integration" begin
    @testset "Complete Documenter build with plot covers and gallery" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            examples_dir = joinpath(src_dir, "examples")
            mkpath(examples_dir)

            # Create index page with overview gallery
            write(
                joinpath(src_dir, "index.md"),
                """
# Test Documentation

This is a test documentation site with Plots.jl cover images.

## Example Gallery

```@overviewgallery
sine_plot
cosine_plot
scatter_plot
```
"""
            )

            # Create example 1: Sine plot
            write(
                joinpath(examples_dir, "sine_plot.md"),
                """
```@cardmeta
Title = "Sine Wave"
Description = "A simple sine wave plot"
Cover = p
```

# Sine Wave Example

This example demonstrates a sine wave plot.

```@example sine_plot
using Plots

p = plot(0:0.1:2π, sin.(0:0.1:2π), 
         title="Sine Wave", 
         xlabel="x", 
         ylabel="sin(x)",
         label="sin(x)",
         linewidth=2)
```
"""
            )

            # Create example 2: Cosine plot
            write(
                joinpath(examples_dir, "cosine_plot.md"),
                """
```@cardmeta
Title = "Cosine Wave"
Description = "A simple cosine wave plot"
Cover = p
```

# Cosine Wave Example

This example demonstrates a cosine wave plot.

```@example cosine_plot
using Plots

p = plot(0:0.1:2π, cos.(0:0.1:2π), 
         title="Cosine Wave", 
         xlabel="x", 
         ylabel="cos(x)",
         label="cos(x)",
         linewidth=2,
         color=:red)
```
"""
            )

            # Create example 3: Scatter plot
            write(
                joinpath(examples_dir, "scatter_plot.md"),
                """
```@cardmeta
Title = "Scatter Plot"
Description = "A scatter plot with random data"
Cover = p
```

# Scatter Plot Example

This example demonstrates a scatter plot.

```@example scatter_plot
using Plots

x = randn(50)
y = randn(50)
p = scatter(x, y, 
            title="Random Scatter", 
            xlabel="x", 
            ylabel="y",
            label="data",
            markersize=6,
            alpha=0.6)
```
"""
            )

            # Build the documentation with ExampleConfig plugin
            build_dir = joinpath(tmpdir, "build")
            doc = makedocs(
                sitename="Plots Test",
                source=src_dir,
                build=build_dir,
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                plugins=[ExampleConfig()],
                pages=[
                    "Home" => "index.md",
                    "Examples" => [
                        "examples/sine_plot.md",
                        "examples/cosine_plot.md",
                        "examples/scatter_plot.md",
                    ]
                ],
                debug=true,
                warnonly=false,
            )

            # Verify the build succeeded
            @test doc isa Documenter.Document

            # Verify HTML files were created
            @test isfile(joinpath(build_dir, "index.html"))
            @test isfile(joinpath(build_dir, "examples", "sine_plot.html"))
            @test isfile(joinpath(build_dir, "examples", "cosine_plot.html"))
            @test isfile(joinpath(build_dir, "examples", "scatter_plot.html"))

            # Read the index.html to verify gallery was generated
            index_html = read(joinpath(build_dir, "index.html"), String)

            # Verify gallery contains our examples
            @test occursin("Sine Wave", index_html)
            @test occursin("Cosine Wave", index_html)
            @test occursin("Scatter Plot", index_html)

            # Verify cover images were generated by checking the HTML contains PNG references
            # With relative paths, they'll be like ../HASH.png or ./HASH.png
            png_matches = collect(eachmatch(r"(?:\.\./|\./)[A-Za-z0-9]+\.png", index_html))

            # Should have at least 3 PNG references (one for each example)
            @test length(png_matches) >= 3

            # Verify gallery HTML structure
            @test occursin("grid-container", index_html) || occursin("gallery", index_html)

            # Verify PNG references in the gallery
            @test occursin(".png", index_html)
        end
    end

    @testset "Plot covers with prettyurls enabled" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            examples_dir = joinpath(src_dir, "examples")
            mkpath(examples_dir)

            # Create simple index
            write(
                joinpath(src_dir, "index.md"),
                """
# Test Site

```@overviewgallery
plot_test
```
"""
            )

            # Create one example with plot
            write(
                joinpath(examples_dir, "plot_test.md"),
                """
```@cardmeta
Title = "Plot Test"
Description = "Testing plots with prettyurls"
Cover = p
```

# Plot Test

Testing prettyurls with plot covers.

```@example plot_test
using Plots
p = plot(1:10, 1:10, title="Test", label="data")
```
"""
            )

            # Build with prettyurls=true
            build_dir = joinpath(tmpdir, "build")
            doc = makedocs(
                sitename="PrettyURLs Test",
                source=src_dir,
                build=build_dir,
                format=Documenter.HTML(prettyurls=true, edit_link=nothing),
                plugins=[ExampleConfig()],
                pages=[
                    "Home" => "index.md",
                    "Examples" => ["examples/plot_test.md"]
                ],
                debug=true,
                warnonly=false,
            )

            # With prettyurls, pages are in subdirectories
            @test isfile(joinpath(build_dir, "index.html"))
            @test isfile(joinpath(build_dir, "examples", "plot_test", "index.html"))

            # Verify PNG reference exists in the HTML
            index_html = read(joinpath(build_dir, "index.html"), String)
            @test occursin(".png", index_html)
        end
    end
end
