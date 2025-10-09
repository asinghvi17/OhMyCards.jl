using Test
using OhMyCards

@testset "Content Conversion Interface" begin
    @testset "Base Interface Behavior" begin
        # Test that the base implementation throws UnsupportedFormatError
        config = CoverImageConfig()
        
        # Test with various content types
        @test_throws UnsupportedFormatError convert_to_format("string content", MIME"image/png"(), config)
        @test_throws UnsupportedFormatError convert_to_format(42, MIME"image/jpeg"(), config)
        @test_throws UnsupportedFormatError convert_to_format([1, 2, 3], MIME"image/webp"(), config)
        @test_throws UnsupportedFormatError convert_to_format(Dict(:a => 1), MIME"image/svg+xml"(), config)
        
        # Test with different MIME types
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"image/png"(), config)
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"image/jpeg"(), config)
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"image/webp"(), config)
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"image/svg+xml"(), config)
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"image/gif"(), config)
        @test_throws UnsupportedFormatError convert_to_format("content", MIME"video/mp4"(), config)
    end
    
    @testset "Error Message Formatting" begin
        config = CoverImageConfig()
        
        # Test UnsupportedFormatError message
        try
            convert_to_format("test", MIME"image/png"(), config)
            @test false  # Should not reach here
        catch e
            @test e isa UnsupportedFormatError
            @test e.content_type == String
            @test e.requested_format == "image/png"
        end
    end
    
    @testset "Interface Contract" begin
        # Test that the function signature exists and is callable
        config = CoverImageConfig()
        
        # Verify the function exists
        @test isdefined(OhMyCards, :convert_to_format)
        
        # Verify it's a function
        @test convert_to_format isa Function
        
        # Verify it throws the right error type for unsupported conversions
        @test_throws UnsupportedFormatError convert_to_format(nothing, MIME"image/png"(), config)
    end
end
