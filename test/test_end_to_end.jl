using Test
using OhMyCards
using Documenter

# Create a mock content type for testing
struct MockImage
    data::Vector{UInt8}
end

# Implement convert_to_format for our mock type
function OhMyCards.convert_to_format(img::MockImage, ::MIME"image/png", config::CoverImageConfig)
    return img.data
end

@testset "End-to-End Integration Tests" begin
    @testset "process_cover_image with mock image - ACTUAL END-TO-END TEST" begin
        # This tests the COMPLETE pipeline with actual file writing and HTML generation
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]

            # Create a mock image with actual PNG header bytes
            png_header = UInt8[137, 80, 78, 71, 13, 10, 26, 10]  # PNG magic bytes
            mock_image = MockImage(png_header)

            config = CoverImageConfig(preferred_format="png", filename_prefix="test_")

            # THIS IS THE REAL TEST - process the image through the complete pipeline
            result = process_cover_image(page, doc, mock_image, config)

            # Verify the file was actually written to disk
            @test isfile(result.file_path)
            @test read(result.file_path) == png_header

            # Verify the filename has the correct prefix
            @test occursin("test_", basename(result.file_path))

            # Verify the file extension is correct
            @test endswith(result.file_path, ".png")

            # Verify the MIME type is correct
            @test result.mime_type == MIME"image/png"()

            # Verify the HTML was generated correctly
            @test occursin("<img", result.html_embed)
            @test occursin("src=", result.html_embed)
            @test occursin(basename(result.file_path), result.html_embed)

            # Verify the relative URL is correct
            @test endswith(result.relative_url, ".png")

            # Verify metadata was captured
            @test haskey(result.metadata, :source_type)
            @test result.metadata[:source_type] == MockImage
            @test haskey(result.metadata, :file_size)
            @test result.metadata[:file_size] == length(png_header)
        end
    end

    @testset "process_cover_image with prettyurls - ACTUAL PATH GENERATION TEST" begin
        # Test that prettyurls affects the generated paths correctly
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "example.md"), "# Example\n")

            # Test with prettyurls=true
            doc_pretty = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build_pretty"),
                format=Documenter.HTML(prettyurls=true, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page_pretty = doc_pretty.blueprint.pages["example.md"]
            mock_image = MockImage(UInt8[137, 80, 78, 71, 13, 10, 26, 10])

            result_pretty = process_cover_image(page_pretty, doc_pretty, mock_image, CoverImageConfig())

            # With prettyurls, the path should be relative (../) since HTML is in example/index.html
            @test startswith(result_pretty.relative_url, "..")
            @test isfile(result_pretty.file_path)

            # Test with prettyurls=false
            doc_no_pretty = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build_no_pretty"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page_no_pretty = doc_no_pretty.blueprint.pages["example.md"]
            result_no_pretty = process_cover_image(page_no_pretty, doc_no_pretty, mock_image, CoverImageConfig())

            # Without prettyurls, the path should be flatter
            @test isfile(result_no_pretty.file_path)

            # The paths should be different
            @test result_pretty.relative_url != result_no_pretty.relative_url
        end
    end

    @testset "prettyurls configuration" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(
                joinpath(src_dir, "example.md"),
                """
# Example

```@cardmeta
Title = "Pretty URLs Test"
```
"""
            )

            # Test with prettyurls=true
            build_dir_pretty = joinpath(tmpdir, "build_pretty")
            doc_pretty = makedocs(
                sitename="Test",
                source=src_dir,
                build=build_dir_pretty,
                format=Documenter.HTML(prettyurls=true, edit_link=nothing),
                plugins=[ExampleConfig()],
                debug=true,
                warnonly=true
            )

            # With prettyurls, pages should be in subdirectories
            @test isfile(joinpath(build_dir_pretty, "index.html"))
            @test isfile(joinpath(build_dir_pretty, "example", "index.html"))

            # Test with prettyurls=false
            build_dir_no_pretty = joinpath(tmpdir, "build_no_pretty")
            doc_no_pretty = makedocs(
                sitename="Test",
                source=src_dir,
                build=build_dir_no_pretty,
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                plugins=[ExampleConfig()],
                debug=true,
                warnonly=true
            )

            # Without prettyurls, pages should be flat
            @test isfile(joinpath(build_dir_no_pretty, "index.html"))
            @test isfile(joinpath(build_dir_no_pretty, "example.html"))
        end
    end

    @testset "Error handling in documentation build" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)

            # Create a page with invalid cardmeta
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(
                joinpath(src_dir, "bad_example.md"),
                """
# Bad Example

```@cardmeta
Title = "This should work"
InvalidField = "This should be ignored with a warning"
```
"""
            )

            build_dir = joinpath(tmpdir, "build")

            # Should still build successfully with warnonly=true
            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=build_dir,
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                plugins=[ExampleConfig()],
                debug=true,
                warnonly=true
            )

            @test doc isa Documenter.Document
            @test isfile(joinpath(build_dir, "index.html"))
            @test isfile(joinpath(build_dir, "bad_example.html"))
        end
    end

    @testset "process_cover_image with different formats" begin
        # Test that the pipeline works with different output formats
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            mock_image = MockImage(UInt8[1, 2, 3, 4])

            # Test PNG format
            config_png = CoverImageConfig(preferred_format="png")
            result_png = process_cover_image(page, doc, mock_image, config_png)
            @test result_png.mime_type == MIME"image/png"()
            @test endswith(result_png.file_path, ".png")
            @test isfile(result_png.file_path)

            # Test JPEG format (need to implement converter for JPEG)
            # For now, this will throw UnsupportedFormatError which is expected
            config_jpeg = CoverImageConfig(preferred_format="jpeg")
            @test_throws UnsupportedFormatError process_cover_image(page, doc, mock_image, config_jpeg)
        end
    end

    @testset "process_cover_image with extension override" begin
        # Test that explicit extension parameter overrides config
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            mock_image = MockImage(UInt8[1, 2, 3, 4])

            # Config says jpeg, but extension override says png
            config = CoverImageConfig(preferred_format="jpeg")
            result = process_cover_image(page, doc, mock_image, config, extension="png")
            
            @test result.mime_type == MIME"image/png"()
            @test endswith(result.file_path, ".png")
            @test isfile(result.file_path)
        end
    end

    @testset "process_cover_image convenience method" begin
        # Test the convenience method that creates config from kwargs
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            mock_image = MockImage(UInt8[1, 2, 3, 4])

            # Use convenience method with kwargs
            result = process_cover_image(page, doc, mock_image, 
                                        preferred_format="png", 
                                        filename_prefix="custom_")
            
            @test result.mime_type == MIME"image/png"()
            @test occursin("custom_", basename(result.file_path))
            @test isfile(result.file_path)
        end
    end

    @testset "process_cover_image metadata" begin
        # Test that metadata is properly captured
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            test_data = UInt8[1, 2, 3, 4, 5]
            mock_image = MockImage(test_data)

            result = process_cover_image(page, doc, mock_image, CoverImageConfig())
            
            # Check metadata fields
            @test haskey(result.metadata, :source_type)
            @test result.metadata[:source_type] == MockImage
            
            @test haskey(result.metadata, :format)
            @test result.metadata[:format] == "image/png"
            
            @test haskey(result.metadata, :file_size)
            @test result.metadata[:file_size] == length(test_data)
        end
    end

    @testset "process_cover_image HTML generation" begin
        # Test that HTML is generated correctly for different formats
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            mock_image = MockImage(UInt8[1, 2, 3, 4])

            # Test PNG HTML generation
            result = process_cover_image(page, doc, mock_image, CoverImageConfig(preferred_format="png"))
            @test occursin("<img", result.html_embed)
            @test occursin("src=", result.html_embed)
            @test occursin(result.relative_url, result.html_embed)
        end
    end

    @testset "process_cover_image with content hash" begin
        # Test that content-based hashing produces consistent filenames
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            
            # Same content should produce same filename
            test_data = UInt8[1, 2, 3, 4, 5]
            mock_image1 = MockImage(test_data)
            mock_image2 = MockImage(test_data)

            config = CoverImageConfig(use_content_hash=true)
            result1 = process_cover_image(page, doc, mock_image1, config)
            result2 = process_cover_image(page, doc, mock_image2, config)
            
            # Same content should produce same filename
            @test basename(result1.file_path) == basename(result2.file_path)
            
            # Different content should produce different filename
            mock_image3 = MockImage(UInt8[5, 4, 3, 2, 1])
            result3 = process_cover_image(page, doc, mock_image3, config)
            @test basename(result1.file_path) != basename(result3.file_path)
        end
    end

    @testset "process_cover_image error handling" begin
        # Test error handling for unsupported content types
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")

            doc = makedocs(
                sitename="Test",
                source=src_dir,
                build=joinpath(tmpdir, "build"),
                format=Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug=true,
                warnonly=true
            )

            page = doc.blueprint.pages["test.md"]
            
            # Try to process an unsupported type
            unsupported_content = "This is just a string"
            config = CoverImageConfig()
            
            @test_throws UnsupportedFormatError process_cover_image(page, doc, unsupported_content, config)
        end
    end
end

# TODO: Uncomment these tests after task 10 (integrate process_cover_image into cardmeta.jl)
# These tests require @cardmeta to actually process the Cover field and call process_cover_image
# to generate actual cover images. Currently they just test that Documenter builds successfully,
# which doesn't verify the cover image processing functionality.
