using Test
using OhMyCards

@testset "Types and Configuration" begin
    @testset "CoverImageConfig" begin
        @testset "Default Configuration" begin
            config = CoverImageConfig()
            @test config.target_height == 600
            @test config.target_width === nothing
            @test config.maintain_aspect_ratio == true
            @test config.preferred_format === nothing
            @test config.fallback_format == "png"
            @test config.jpeg_quality == 85
            @test config.webp_quality == 80
            @test config.mp4_fps == 30
            @test config.mp4_duration === nothing
            @test config.video_autoplay == true
            @test config.video_loop == true
            @test config.video_muted == true
            @test config.video_controls == false
            @test config.filename_prefix == ""
            @test config.use_content_hash == true
        end
        
        @testset "Custom Configuration" begin
            config = CoverImageConfig(
                target_height=800,
                target_width=1200,
                maintain_aspect_ratio=false,
                preferred_format="jpeg",
                fallback_format="webp",
                jpeg_quality=95,
                webp_quality=90,
                mp4_fps=60,
                mp4_duration=5.0,
                video_autoplay=false,
                video_loop=false,
                video_muted=false,
                video_controls=true,
                filename_prefix="cover_",
                use_content_hash=false
            )
            @test config.target_height == 800
            @test config.target_width == 1200
            @test config.maintain_aspect_ratio == false
            @test config.preferred_format == "jpeg"
            @test config.fallback_format == "webp"
            @test config.jpeg_quality == 95
            @test config.webp_quality == 90
            @test config.mp4_fps == 60
            @test config.mp4_duration == 5.0
            @test config.video_autoplay == false
            @test config.video_loop == false
            @test config.video_muted == false
            @test config.video_controls == true
            @test config.filename_prefix == "cover_"
            @test config.use_content_hash == false
        end
        
        @testset "Configuration Validation" begin
            # Test valid configuration
            @test validate_config(CoverImageConfig()) == true
            
            # Test invalid target_height
            @test_throws ArgumentError CoverImageConfig(target_height=0)
            @test_throws ArgumentError CoverImageConfig(target_height=-100)
            
            # Test invalid target_width
            @test_throws ArgumentError CoverImageConfig(target_width=0)
            @test_throws ArgumentError CoverImageConfig(target_width=-50)
            
            # Test invalid preferred_format
            @test_throws ArgumentError CoverImageConfig(preferred_format="invalid")
            @test_throws ArgumentError CoverImageConfig(preferred_format="bmp")
            
            # Test invalid fallback_format
            @test_throws ArgumentError CoverImageConfig(fallback_format="invalid")
            @test_throws ArgumentError CoverImageConfig(fallback_format="tiff")
            
            # Test invalid jpeg_quality
            @test_throws ArgumentError CoverImageConfig(jpeg_quality=0)
            @test_throws ArgumentError CoverImageConfig(jpeg_quality=101)
            @test_throws ArgumentError CoverImageConfig(jpeg_quality=-10)
            
            # Test invalid webp_quality
            @test_throws ArgumentError CoverImageConfig(webp_quality=0)
            @test_throws ArgumentError CoverImageConfig(webp_quality=101)
            @test_throws ArgumentError CoverImageConfig(webp_quality=-5)
            
            # Test invalid mp4_fps
            @test_throws ArgumentError CoverImageConfig(mp4_fps=0)
            @test_throws ArgumentError CoverImageConfig(mp4_fps=-30)
            
            # Test invalid mp4_duration
            @test_throws ArgumentError CoverImageConfig(mp4_duration=0.0)
            @test_throws ArgumentError CoverImageConfig(mp4_duration=-1.5)
            
            # Test valid edge cases
            @test validate_config(CoverImageConfig(jpeg_quality=1)) == true
            @test validate_config(CoverImageConfig(jpeg_quality=100)) == true
            @test validate_config(CoverImageConfig(webp_quality=1)) == true
            @test validate_config(CoverImageConfig(webp_quality=100)) == true
            @test validate_config(CoverImageConfig(preferred_format="png")) == true
            @test validate_config(CoverImageConfig(preferred_format="jpeg")) == true
            @test validate_config(CoverImageConfig(preferred_format="webp")) == true
            @test validate_config(CoverImageConfig(preferred_format="svg")) == true
            @test validate_config(CoverImageConfig(preferred_format="gif")) == true
            @test validate_config(CoverImageConfig(preferred_format="mp4")) == true
        end
    end
    
    @testset "CoverImageResult" begin
        @testset "Construction" begin
            result = CoverImageResult(
                "/path/to/image.png",
                "assets/image.png",
                MIME"image/png"(),
                "<img src=\"assets/image.png\" alt=\"\" />",
                Dict{Symbol, Any}(:width => 800, :height => 600)
            )
            
            @test result.file_path == "/path/to/image.png"
            @test result.relative_url == "assets/image.png"
            @test result.mime_type == MIME"image/png"()
            @test result.html_embed == "<img src=\"assets/image.png\" alt=\"\" />"
            @test result.metadata[:width] == 800
            @test result.metadata[:height] == 600
        end
        
        @testset "Different MIME Types" begin
            # Test with different MIME types
            png_result = CoverImageResult(
                "/path/to/image.png", "image.png", MIME"image/png"(),
                "<img src=\"image.png\" alt=\"\" />", Dict{Symbol, Any}()
            )
            @test png_result.mime_type == MIME"image/png"()
            
            jpeg_result = CoverImageResult(
                "/path/to/image.jpg", "image.jpg", MIME"image/jpeg"(),
                "<img src=\"image.jpg\" alt=\"\" />", Dict{Symbol, Any}()
            )
            @test jpeg_result.mime_type == MIME"image/jpeg"()
            
            video_result = CoverImageResult(
                "/path/to/video.mp4", "video.mp4", MIME"video/mp4"(),
                "<video autoplay loop muted><source src=\"video.mp4\" type=\"video/mp4\"></video>",
                Dict{Symbol, Any}()
            )
            @test video_result.mime_type == MIME"video/mp4"()
        end
    end
    
    @testset "Exception Types" begin
        @testset "UnsupportedFormatError" begin
            error = UnsupportedFormatError(String, "bmp")
            @test error.content_type == String
            @test error.requested_format == "bmp"
            @test error isa CoverImageError
            @test error isa Exception
        end
        
        @testset "ConversionError" begin
            original_error = ArgumentError("test error")
            error = ConversionError(Int, "png", original_error)
            @test error.content_type == Int
            @test error.format == "png"
            @test error.original_error == original_error
            @test error isa CoverImageError
            @test error isa Exception
        end
        
        @testset "PathGenerationError" begin
            error = PathGenerationError("Invalid path structure")
            @test error.reason == "Invalid path structure"
            @test error isa CoverImageError
            @test error isa Exception
        end
    end
end
