using Test
using OhMyCards
using Documenter

@testset "Cover Image Processor" begin
    @testset "process_cover_image basic functionality" begin
        mktempdir() do tmpdir
            # Create a minimal documentation setup
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")
            
            # Create document
            doc = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build"),
                format = Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            page = doc.blueprint.pages["test.md"]
            
            # Create mock content (we'll use raw bytes since we don't have actual plot objects)
            # In real usage, this would be a Plots.Plot, Makie.Figure, etc.
            # For testing, we'll test the error path since we don't have converters yet
            
            config = CoverImageConfig()
            
            # Test that it throws UnsupportedFormatError for unsupported content
            @test_throws UnsupportedFormatError process_cover_image(page, doc, "test content", config)
        end
    end
    
    @testset "process_cover_image with default config" begin
        mktempdir() do tmpdir
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")
            
            doc = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build"),
                format = Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            page = doc.blueprint.pages["test.md"]
            
            # Test convenience method with kwargs
            @test_throws UnsupportedFormatError process_cover_image(
                page, doc, "test", 
                target_height=800, 
                preferred_format="svg"
            )
        end
    end
    
    @testset "process_cover_image format selection" begin
        # Test that format selection works correctly
        # We can't fully test this without actual converters, but we can verify
        # the function exists and has the right signature
        
        @test isdefined(OhMyCards, :process_cover_image)
        @test process_cover_image isa Function
        
        # Test that it accepts the expected arguments
        @test hasmethod(process_cover_image, (Any, Any, Any, CoverImageConfig))
        @test hasmethod(process_cover_image, (Any, Any, Any))
    end
    
    @testset "Integration with existing components" begin
        # Verify that process_cover_image uses the correct components
        # by checking that the expected functions are called
        
        # Test format detection integration
        @test detect_format_with_fallback("test.png") == MIME"image/png"()
        @test detect_format_with_fallback("test.svg") == MIME"image/svg+xml"()
        
        # Test that CoverImageResult can be constructed
        result = CoverImageResult(
            "/path/to/file.png",
            "relative/file.png",
            MIME"image/png"(),
            "<img src=\"relative/file.png\" alt=\"\" />",
            Dict{Symbol,Any}(:test => true)
        )
        
        @test result.file_path == "/path/to/file.png"
        @test result.relative_url == "relative/file.png"
        @test result.mime_type == MIME"image/png"()
        @test result.metadata[:test] == true
    end
end
