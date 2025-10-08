using Test
using OhMyCards

@testset "Format Detection" begin
    @testset "MIME_MAPPING Dictionary" begin
        # Test that all expected formats are present
        @test haskey(MIME_MAPPING, ".png")
        @test haskey(MIME_MAPPING, ".jpg")
        @test haskey(MIME_MAPPING, ".jpeg")
        @test haskey(MIME_MAPPING, ".webp")
        @test haskey(MIME_MAPPING, ".svg")
        @test haskey(MIME_MAPPING, ".gif")
        @test haskey(MIME_MAPPING, ".mp4")
        
        # Test correct MIME types
        @test MIME_MAPPING[".png"] == MIME"image/png"()
        @test MIME_MAPPING[".jpg"] == MIME"image/jpeg"()
        @test MIME_MAPPING[".jpeg"] == MIME"image/jpeg"()
        @test MIME_MAPPING[".webp"] == MIME"image/webp"()
        @test MIME_MAPPING[".svg"] == MIME"image/svg+xml"()
        @test MIME_MAPPING[".gif"] == MIME"image/gif"()
        @test MIME_MAPPING[".mp4"] == MIME"video/mp4"()
    end
    
    @testset "detect_format Function" begin
        # Test standard image formats
        @test detect_format("image.png") == MIME"image/png"()
        @test detect_format("photo.jpg") == MIME"image/jpeg"()
        @test detect_format("picture.jpeg") == MIME"image/jpeg"()
        @test detect_format("graphic.webp") == MIME"image/webp"()
        @test detect_format("vector.svg") == MIME"image/svg+xml"()
        @test detect_format("animation.gif") == MIME"image/gif"()
        
        # Test video format
        @test detect_format("video.mp4") == MIME"video/mp4"()
        
        # Test case insensitivity
        @test detect_format("IMAGE.PNG") == MIME"image/png"()
        @test detect_format("Photo.JPG") == MIME"image/jpeg"()
        @test detect_format("Picture.JPEG") == MIME"image/jpeg"()
        @test detect_format("Graphic.WEBP") == MIME"image/webp"()
        @test detect_format("Vector.SVG") == MIME"image/svg+xml"()
        @test detect_format("Animation.GIF") == MIME"image/gif"()
        @test detect_format("Video.MP4") == MIME"video/mp4"()
        
        # Test mixed case
        @test detect_format("file.Png") == MIME"image/png"()
        @test detect_format("file.JpG") == MIME"image/jpeg"()
        @test detect_format("file.WebP") == MIME"image/webp"()
        
        # Test unknown extensions return nothing
        @test detect_format("unknown.xyz") === nothing
        @test detect_format("file.bmp") === nothing
        @test detect_format("document.tiff") === nothing
        @test detect_format("archive.zip") === nothing
        @test detect_format("text.txt") === nothing
        
        # Test edge cases
        @test detect_format("file") === nothing     # No extension
        @test detect_format("") === nothing         # Empty string
        @test detect_format(".png") == MIME"image/png"()  # Extension only
        @test detect_format("file.") === nothing    # Trailing dot
        
        # Test files with multiple dots
        @test detect_format("my.file.name.png") == MIME"image/png"()
        @test detect_format("backup.2023.jpg") == MIME"image/jpeg"()
        @test detect_format("version.1.0.svg") == MIME"image/svg+xml"()
        
        # Test paths with directories
        @test detect_format("/path/to/image.png") == MIME"image/png"()
        @test detect_format("./relative/path/photo.jpg") == MIME"image/jpeg"()
        @test detect_format("../parent/video.mp4") == MIME"video/mp4"()
        @test detect_format("C:\\Windows\\path\\image.gif") == MIME"image/gif"()
    end
    
    @testset "Format Detection Edge Cases" begin
        # Test with special characters in filename
        @test detect_format("image with spaces.png") == MIME"image/png"()
        @test detect_format("image-with-dashes.jpg") == MIME"image/jpeg"()
        @test detect_format("image_with_underscores.webp") == MIME"image/webp"()
        @test detect_format("image@2x.png") == MIME"image/png"()
        @test detect_format("image(1).jpg") == MIME"image/jpeg"()
        
        # Test Unicode characters
        @test detect_format("图片.png") == MIME"image/png"()
        @test detect_format("画像.jpg") == MIME"image/jpeg"()
        @test detect_format("εικόνα.svg") == MIME"image/svg+xml"()
        
        # Test very long filenames
        long_name = "a" ^ 200 * ".png"
        @test detect_format(long_name) == MIME"image/png"()
        
        # Test extension with numbers
        @test detect_format("file.mp4") == MIME"video/mp4"()
        @test detect_format("file.h264") === nothing  # Should return nothing
    end
    
    @testset "detect_format_with_fallback Function" begin
        # Test known formats (should behave same as detect_format)
        @test detect_format_with_fallback("image.png") == MIME"image/png"()
        @test detect_format_with_fallback("photo.jpg") == MIME"image/jpeg"()
        @test detect_format_with_fallback("video.mp4") == MIME"video/mp4"()
        
        # Test unknown formats with default fallback (PNG)
        @test detect_format_with_fallback("unknown.xyz") == MIME"image/png"()
        @test detect_format_with_fallback("file.bmp") == MIME"image/png"()
        @test detect_format_with_fallback("file") == MIME"image/png"()
        @test detect_format_with_fallback("") == MIME"image/png"()
        
        # Test unknown formats with custom fallback
        @test detect_format_with_fallback("unknown.xyz", MIME"image/jpeg"()) == MIME"image/jpeg"()
        @test detect_format_with_fallback("file.bmp", MIME"image/webp"()) == MIME"image/webp"()
        @test detect_format_with_fallback("file", MIME"video/mp4"()) == MIME"video/mp4"()
        
        # Test that known formats override fallback
        @test detect_format_with_fallback("image.png", MIME"image/jpeg"()) == MIME"image/png"()
        @test detect_format_with_fallback("video.mp4", MIME"image/png"()) == MIME"video/mp4"()
    end
end
