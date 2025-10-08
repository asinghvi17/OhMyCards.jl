# Tests for Makie extension with new MIME-based system

using Test
using OhMyCards
using CairoMakie  # Use CairoMakie for testing (supports PNG, SVG, PDF)
using Documenter

@testset "Makie Extension - MIME-based Conversion" begin
    @testset "convert_to_format - PNG format" begin
        # Create a simple Makie figure
        fig = Figure()
        ax = Axis(fig[1, 1], title="Test Figure")
        lines!(ax, 1:10, sin.(1:10), label="sin(x)")
        
        # Test PNG conversion
        config = CoverImageConfig(target_height=600, preferred_format="png")
        bytes = OhMyCards.convert_to_format(fig, MIME"image/png"(), config)
        
        # Verify we got bytes back
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
        
        # Verify it's a valid PNG (starts with PNG magic bytes)
        @test bytes[1:4] == UInt8[0x89, 0x50, 0x4e, 0x47]
    end
    
    @testset "convert_to_format - SVG format" begin
        # Create a simple Makie figure
        fig = Figure()
        ax = Axis(fig[1, 1], title="Test Figure")
        lines!(ax, 1:10, cos.(1:10), label="cos(x)")
        
        # Test SVG conversion
        config = CoverImageConfig(target_height=600, preferred_format="svg")
        bytes = OhMyCards.convert_to_format(fig, MIME"image/svg+xml"(), config)
        
        # Verify we got bytes back
        @test bytes isa Vector{UInt8}
        @test length(bytes) > 0
        
        # Verify it's valid SVG (contains SVG tags)
        svg_string = String(bytes)
        @test occursin("<svg", svg_string)
        @test occursin("</svg>", svg_string)
    end
    
    @testset "convert_to_format - Multiple formats" begin
        # Create a simple Makie figure
        fig = Figure()
        ax = Axis(fig[1, 1], title="Test Figure")
        lines!(ax, 1:10, exp.(1:10), label="exp(x)")
        
        # Test that we can convert to different formats
        config_png = CoverImageConfig(target_height=600, preferred_format="png")
        bytes_png = OhMyCards.convert_to_format(fig, MIME"image/png"(), config_png)
        @test bytes_png isa Vector{UInt8}
        @test length(bytes_png) > 0
        
        config_svg = CoverImageConfig(target_height=600, preferred_format="svg")
        bytes_svg = OhMyCards.convert_to_format(fig, MIME"image/svg+xml"(), config_svg)
        @test bytes_svg isa Vector{UInt8}
        @test length(bytes_svg) > 0
        
        # SVG and PNG should produce different outputs
        @test bytes_png != bytes_svg
    end
    
    @testset "convert_to_format - Dimension handling" begin
        # Test with target height only
        fig1 = Figure(resolution=(800, 600))
        ax1 = Axis(fig1[1, 1], title="Test Figure")
        lines!(ax1, 1:10, sin.(1:10))
        
        config_height = CoverImageConfig(target_height=300, target_width=nothing)
        bytes_height = OhMyCards.convert_to_format(fig1, MIME"image/png"(), config_height)
        @test bytes_height isa Vector{UInt8}
        @test length(bytes_height) > 0
        
        # Test with target width only - use a fresh figure
        fig2 = Figure(resolution=(800, 600))
        ax2 = Axis(fig2[1, 1], title="Test Figure")
        lines!(ax2, 1:10, sin.(1:10))
        
        config_width = CoverImageConfig(target_height=nothing, target_width=400)
        bytes_width = OhMyCards.convert_to_format(fig2, MIME"image/png"(), config_width)
        @test bytes_width isa Vector{UInt8}
        @test length(bytes_width) > 0
        
        # Test with both dimensions - use a fresh figure
        fig3 = Figure(resolution=(800, 600))
        ax3 = Axis(fig3[1, 1], title="Test Figure")
        lines!(ax3, 1:10, sin.(1:10))
        
        config_both = CoverImageConfig(target_height=300, target_width=400)
        bytes_both = OhMyCards.convert_to_format(fig3, MIME"image/png"(), config_both)
        @test bytes_both isa Vector{UInt8}
        @test length(bytes_both) > 0
        
        # Verify that bytes were generated (actual size comparison is tricky due to compression)
        @test length(bytes_height) > 100  # Reasonable minimum size
        @test length(bytes_width) > 100
        @test length(bytes_both) > 100
    end
    
    @testset "convert_to_format - Error handling" begin
        # Create a figure
        fig = Figure()
        ax = Axis(fig[1, 1])
        lines!(ax, 1:10, sin.(1:10))
        
        # Test that conversion errors are properly wrapped
        config = CoverImageConfig()
        
        # This should work fine for supported formats
        @test_nowarn OhMyCards.convert_to_format(fig, MIME"image/png"(), config)
        
        # Unsupported format should throw UnsupportedFormatError
        @test_throws OhMyCards.UnsupportedFormatError OhMyCards.convert_to_format(fig, MIME"image/tiff"(), config)
    end
end

@testset "Makie Extension - Backward Compatibility" begin
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
            
            # Get the page object
            page = first(values(doc.blueprint.pages))
            
            # Create a Makie figure
            fig = Figure()
            ax = Axis(fig[1, 1])
            lines!(ax, 1:10, sin.(1:10))
            
            # Call get_image_url
            url = OhMyCards.get_image_url(page, doc, fig)
            
            # Verify URL format
            @test url isa String
            @test startswith(url, "/")
            @test endswith(url, ".png")
            
            # Verify file was created
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
            
            # Get the page object
            page = first(values(doc.blueprint.pages))
            
            # Create a Makie figure
            fig = Figure()
            ax = Axis(fig[1, 1])
            lines!(ax, 1:10, cos.(1:10))
            
            # Create meta dictionary
            meta = Dict{Symbol, Any}()
            
            # Call set_cover_to_image!
            OhMyCards.set_cover_to_image!(meta, page, doc, fig)
            
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
    
    @testset "Error handling in backward compatibility functions" begin
        mktempdir() do tmpdir
            # Create mock page and doc objects
            src_dir = joinpath(tmpdir, "src")
            build_dir = joinpath(tmpdir, "build")
            mkpath(src_dir)
            mkpath(build_dir)
            
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
            
            page = first(values(doc.blueprint.pages))
            
            # Create a valid figure
            fig = Figure()
            ax = Axis(fig[1, 1])
            lines!(ax, 1:10, sin.(1:10))
            
            # get_image_url should handle errors gracefully and return a fallback
            url = OhMyCards.get_image_url(page, doc, fig)
            @test url isa String
            @test startswith(url, "/")
            
            # set_cover_to_image! should propagate errors for invalid input
            meta = Dict{Symbol, Any}()
            # This should work with a valid figure
            @test_nowarn OhMyCards.set_cover_to_image!(meta, page, doc, fig)
            @test haskey(meta, :Cover)
        end
    end
end

@testset "Makie Extension - Full End-to-End Integration" begin
    @testset "Complete Documenter build with Makie covers and gallery" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            examples_dir = joinpath(src_dir, "examples")
            mkpath(examples_dir)

            # Create index page with overview gallery
            write(
                joinpath(src_dir, "index.md"),
                """
# Test Documentation

This is a test documentation site with Makie.jl cover images.

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
Cover = fig
```

# Sine Wave Example

This example demonstrates a sine wave plot with Makie.

```@example sine_plot
using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1], title="Sine Wave", xlabel="x", ylabel="sin(x)")
lines!(ax, 0:0.1:2π, sin.(0:0.1:2π), label="sin(x)", linewidth=2)
fig
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
Cover = fig
```

# Cosine Wave Example

This example demonstrates a cosine wave plot with Makie.

```@example cosine_plot
using CairoMakie

fig = Figure()
ax = Axis(fig[1, 1], title="Cosine Wave", xlabel="x", ylabel="cos(x)")
lines!(ax, 0:0.1:2π, cos.(0:0.1:2π), label="cos(x)", linewidth=2, color=:red)
fig
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
Cover = fig
```

# Scatter Plot Example

This example demonstrates a scatter plot with Makie.

```@example scatter_plot
using CairoMakie

x = randn(50)
y = randn(50)
fig = Figure()
ax = Axis(fig[1, 1], title="Random Scatter", xlabel="x", ylabel="y")
scatter!(ax, x, y, label="data", markersize=12, alpha=0.6)
fig
```
"""
            )

            # Build the documentation with ExampleConfig plugin
            build_dir = joinpath(tmpdir, "build")
            doc = makedocs(
                sitename="Makie Test",
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
            png_matches = collect(eachmatch(r"/examples/[A-Za-z0-9]+\.png", index_html))

            # Should have at least 3 PNG references (one for each example)
            @test length(png_matches) >= 3

            # Verify gallery HTML structure
            @test occursin("grid-container", index_html) || occursin("gallery", index_html)

            # Verify PNG references in the gallery
            @test occursin(".png", index_html)
        end
    end

    @testset "Makie covers with prettyurls enabled" begin
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
makie_test
```
"""
            )

            # Create one example with Makie figure
            write(
                joinpath(examples_dir, "makie_test.md"),
                """
```@cardmeta
Title = "Makie Test"
Description = "Testing Makie with prettyurls"
Cover = fig
```

# Makie Test

Testing prettyurls with Makie covers.

```@example makie_test
using CairoMakie
fig = Figure()
ax = Axis(fig[1, 1], title="Test")
lines!(ax, 1:10, 1:10, label="data")
fig
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
                    "Examples" => ["examples/makie_test.md"]
                ],
                debug=true,
                warnonly=false,
            )

            # With prettyurls, pages are in subdirectories
            @test isfile(joinpath(build_dir, "index.html"))
            @test isfile(joinpath(build_dir, "examples", "makie_test", "index.html"))

            # Verify PNG reference exists in the HTML
            index_html = read(joinpath(build_dir, "index.html"), String)
            @test occursin(".png", index_html)
        end
    end
end
