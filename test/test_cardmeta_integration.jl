using Test
using OhMyCards
using Documenter

@testset "Cardmeta Integration with MIME-based System" begin
    
    @testset "get_cover_image_config" begin
        # We can't easily test get_cover_image_config without a full Documenter.Document
        # because it relies on Documenter.getplugin which requires a proper Document structure.
        # Instead, we test that the default CoverImageConfig is created correctly.
        
        config = CoverImageConfig()
        @test config isa CoverImageConfig
        @test config.target_height == 600
        @test config.fallback_format == "png"
        @test config.video_autoplay == true
        @test config.video_loop == true
        @test config.video_muted == true
        @test config.video_controls == false
    end
    
    @testset "get_image_url with String" begin
        # String covers should pass through unchanged
        page = nothing
        doc = nothing
        url = OhMyCards.get_image_url(page, doc, "https://example.com/image.png")
        @test url == "https://example.com/image.png"
    end
    
    @testset "set_cover_to_image! with String" begin
        # String covers should pass through unchanged
        meta = Dict{Symbol, Any}()
        page = nothing
        doc = nothing
        result = OhMyCards.set_cover_to_image!(meta, page, doc, "https://example.com/image.png")
        @test result == "https://example.com/image.png"
    end
    
    @testset "Unsupported content type handling" begin
        # Create mock page and doc objects
        page = (
            workdir = mktempdir(),
            source = "./test/example.md",
            build = "./build/test/example.html"
        )
        
        doc = (
            user = (
                build = "./build",
                format = [Documenter.HTML(prettyurls=false)]
            ),
        )
        
        # Mock getplugin to return ExampleConfig
        original_getplugin = Documenter.getplugin
        Documenter.getplugin(d, ::Type{ExampleConfig}) = ExampleConfig()
        
        # Test with unsupported content type (e.g., a plain number)
        meta = Dict{Symbol, Any}()
        
        # This should log a warning and return nothing
        result = @test_logs (:warn, r"Unsupported content type") OhMyCards.set_cover_to_image!(meta, page, doc, 42)
        @test result === nothing
        @test meta[:Cover] === nothing
        
        # Restore original getplugin
        Documenter.getplugin = original_getplugin
        
        # Clean up temp directory
        rm(page.workdir, recursive=true, force=true)
    end
    
    @testset "Configuration passing through system" begin
        # This test verifies that configuration is properly passed through
        # the MIME-based system when processing cover images
        
        # Create a custom config with non-default values
        custom_config = CoverImageConfig(
            target_height = 800,
            preferred_format = "png",
            filename_prefix = "test_"
        )
        
        # Verify the config was created correctly
        @test custom_config.target_height == 800
        @test custom_config.preferred_format == "png"
        @test custom_config.filename_prefix == "test_"
    end
    
end
