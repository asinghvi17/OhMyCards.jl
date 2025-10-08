using Test
using OhMyCards

@testset "HTML Embedding System" begin
    @testset "Static Image Formats" begin
        @testset "PNG Images" begin
            # Basic PNG embedding
            html = embeddable_html(MIME"image/png"(), "image.png", Dict{Symbol,Any}())
            @test html == "<img src=\"image.png\" alt=\"\" />"
            
            # PNG with alt text
            html = embeddable_html(MIME"image/png"(), "cover.png", Dict{Symbol,Any}(:alt => "Cover image"))
            @test html == "<img src=\"cover.png\" alt=\"Cover image\" />"
            
            # PNG with CSS class
            html = embeddable_html(MIME"image/png"(), "styled.png", Dict{Symbol,Any}(:class => "cover-image"))
            @test html == "<img src=\"styled.png\" alt=\"\" class=\"cover-image\" />"
            
            # PNG with inline style
            html = embeddable_html(MIME"image/png"(), "sized.png", Dict{Symbol,Any}(:style => "width: 100px;"))
            @test html == "<img src=\"sized.png\" alt=\"\" style=\"width: 100px;\" />"
            
            # PNG with all attributes
            options = Dict{Symbol,Any}(
                :alt => "Test image",
                :class => "test-class",
                :style => "border: 1px solid black;"
            )
            html = embeddable_html(MIME"image/png"(), "full.png", options)
            @test html == "<img src=\"full.png\" alt=\"Test image\" class=\"test-class\" style=\"border: 1px solid black;\" />"
        end
        
        @testset "JPEG Images" begin
            # Basic JPEG embedding
            html = embeddable_html(MIME"image/jpeg"(), "photo.jpg", Dict{Symbol,Any}())
            @test html == "<img src=\"photo.jpg\" alt=\"\" />"
            
            # JPEG with attributes
            options = Dict{Symbol,Any}(:alt => "Photo", :class => "photo")
            html = embeddable_html(MIME"image/jpeg"(), "portrait.jpg", options)
            @test html == "<img src=\"portrait.jpg\" alt=\"Photo\" class=\"photo\" />"
        end
        
        @testset "WebP Images" begin
            # Basic WebP embedding
            html = embeddable_html(MIME"image/webp"(), "modern.webp", Dict{Symbol,Any}())
            @test html == "<img src=\"modern.webp\" alt=\"\" />"
            
            # WebP with styling
            options = Dict{Symbol,Any}(:style => "max-width: 500px;")
            html = embeddable_html(MIME"image/webp"(), "optimized.webp", options)
            @test html == "<img src=\"optimized.webp\" alt=\"\" style=\"max-width: 500px;\" />"
        end
    end
    
    @testset "SVG Format with Special Handling" begin
        # Basic SVG embedding
        html = embeddable_html(MIME"image/svg+xml"(), "vector.svg", Dict{Symbol,Any}())
        expected = "<img src=\"vector.svg\" alt=\"\" style=\"max-width: 100%; height: auto;\" />"
        @test html == expected
        
        # SVG with alt text
        html = embeddable_html(MIME"image/svg+xml"(), "icon.svg", Dict{Symbol,Any}(:alt => "Icon"))
        expected = "<img src=\"icon.svg\" alt=\"Icon\" style=\"max-width: 100%; height: auto;\" />"
        @test html == expected
        
        # SVG with CSS class
        html = embeddable_html(MIME"image/svg+xml"(), "logo.svg", Dict{Symbol,Any}(:class => "logo"))
        expected = "<img src=\"logo.svg\" alt=\"\" class=\"logo\" style=\"max-width: 100%; height: auto;\" />"
        @test html == expected
        
        # SVG with custom style (should merge with default SVG style)
        html = embeddable_html(MIME"image/svg+xml"(), "custom.svg", Dict{Symbol,Any}(:style => "color: red;"))
        expected = "<img src=\"custom.svg\" alt=\"\" style=\"color: red; max-width: 100%; height: auto;\" />"
        @test html == expected
        
        # SVG with all attributes
        options = Dict{Symbol,Any}(
            :alt => "Vector graphic",
            :class => "svg-icon",
            :style => "fill: blue;"
        )
        html = embeddable_html(MIME"image/svg+xml"(), "complete.svg", options)
        expected = "<img src=\"complete.svg\" alt=\"Vector graphic\" class=\"svg-icon\" style=\"fill: blue; max-width: 100%; height: auto;\" />"
        @test html == expected
    end
    
    @testset "GIF Format for Animation" begin
        # Basic GIF embedding
        html = embeddable_html(MIME"image/gif"(), "animation.gif", Dict{Symbol,Any}())
        @test html == "<img src=\"animation.gif\" alt=\"\" />"
        
        # GIF with attributes
        options = Dict{Symbol,Any}(:alt => "Animated GIF", :class => "animation")
        html = embeddable_html(MIME"image/gif"(), "spinner.gif", options)
        @test html == "<img src=\"spinner.gif\" alt=\"Animated GIF\" class=\"animation\" />"
    end
    
    @testset "Video Format with Configurable Attributes" begin
        @testset "Default Video Attributes" begin
            # Basic MP4 embedding with defaults
            html = embeddable_html(MIME"video/mp4"(), "video.mp4", Dict{Symbol,Any}())
            @test html == "<video autoplay loop muted><source src=\"video.mp4\" type=\"video/mp4\"></video>"
        end
        
        @testset "Custom Video Attributes" begin
            # Video with autoplay disabled
            options = Dict{Symbol,Any}(:autoplay => false)
            html = embeddable_html(MIME"video/mp4"(), "manual.mp4", options)
            @test html == "<video loop muted><source src=\"manual.mp4\" type=\"video/mp4\"></video>"
            
            # Video with loop disabled
            options = Dict{Symbol,Any}(:loop => false)
            html = embeddable_html(MIME"video/mp4"(), "once.mp4", options)
            @test html == "<video autoplay muted><source src=\"once.mp4\" type=\"video/mp4\"></video>"
            
            # Video with sound enabled
            options = Dict{Symbol,Any}(:muted => false)
            html = embeddable_html(MIME"video/mp4"(), "sound.mp4", options)
            @test html == "<video autoplay loop><source src=\"sound.mp4\" type=\"video/mp4\"></video>"
            
            # Video with controls enabled
            options = Dict{Symbol,Any}(:controls => true)
            html = embeddable_html(MIME"video/mp4"(), "controlled.mp4", options)
            @test html == "<video autoplay loop muted controls><source src=\"controlled.mp4\" type=\"video/mp4\"></video>"
            
            # Video with all attributes disabled/enabled
            options = Dict{Symbol,Any}(
                :autoplay => false,
                :loop => false,
                :muted => false,
                :controls => true
            )
            html = embeddable_html(MIME"video/mp4"(), "custom.mp4", options)
            @test html == "<video controls><source src=\"custom.mp4\" type=\"video/mp4\"></video>"
        end
        
        @testset "Video with CSS Styling" begin
            # Video with CSS class
            options = Dict{Symbol,Any}(:class => "cover-video")
            html = embeddable_html(MIME"video/mp4"(), "styled.mp4", options)
            @test html == "<video autoplay loop muted class=\"cover-video\"><source src=\"styled.mp4\" type=\"video/mp4\"></video>"
            
            # Video with inline style
            options = Dict{Symbol,Any}(:style => "width: 100%; height: auto;")
            html = embeddable_html(MIME"video/mp4"(), "responsive.mp4", options)
            @test html == "<video autoplay loop muted style=\"width: 100%; height: auto;\"><source src=\"responsive.mp4\" type=\"video/mp4\"></video>"
            
            # Video with both class and style
            options = Dict{Symbol,Any}(
                :class => "video-player",
                :style => "border-radius: 8px;"
            )
            html = embeddable_html(MIME"video/mp4"(), "rounded.mp4", options)
            @test html == "<video autoplay loop muted class=\"video-player\" style=\"border-radius: 8px;\"><source src=\"rounded.mp4\" type=\"video/mp4\"></video>"
        end
        
        @testset "Complex Video Configuration" begin
            # Video with all possible options
            options = Dict{Symbol,Any}(
                :autoplay => true,
                :loop => false,
                :muted => false,
                :controls => true,
                :class => "full-featured-video",
                :style => "max-width: 800px; margin: 0 auto;"
            )
            html = embeddable_html(MIME"video/mp4"(), "complete.mp4", options)
            expected = "<video autoplay controls class=\"full-featured-video\" style=\"max-width: 800px; margin: 0 auto;\"><source src=\"complete.mp4\" type=\"video/mp4\"></video>"
            @test html == expected
        end
    end
    
    @testset "Unsupported MIME Types" begin
        # Test that unsupported MIME types throw errors
        @test_throws ErrorException embeddable_html(MIME"text/plain"(), "file.txt", Dict{Symbol,Any}())
        @test_throws ErrorException embeddable_html(MIME"application/pdf"(), "document.pdf", Dict{Symbol,Any}())
        @test_throws ErrorException embeddable_html(MIME"audio/mp3"(), "music.mp3", Dict{Symbol,Any}())
    end
    
    @testset "CoverImageConfig Integration" begin
        @testset "Default Config Integration" begin
            config = CoverImageConfig()
            
            # Test video with default config
            html = embeddable_html(MIME"video/mp4"(), "config_test.mp4", config)
            @test html == "<video autoplay loop muted><source src=\"config_test.mp4\" type=\"video/mp4\"></video>"
            
            # Test image with config (should work same as basic)
            html = embeddable_html(MIME"image/png"(), "config_test.png", config)
            @test html == "<img src=\"config_test.png\" alt=\"\" />"
        end
        
        @testset "Custom Config Integration" begin
            config = CoverImageConfig(
                video_autoplay=false,
                video_loop=false,
                video_muted=false,
                video_controls=true
            )
            
            html = embeddable_html(MIME"video/mp4"(), "custom_config.mp4", config)
            @test html == "<video controls><source src=\"custom_config.mp4\" type=\"video/mp4\"></video>"
        end
    end
    
    @testset "Edge Cases and Special Characters" begin
        @testset "Special Characters in Filenames" begin
            # Test with spaces
            html = embeddable_html(MIME"image/png"(), "file with spaces.png", Dict{Symbol,Any}())
            @test html == "<img src=\"file with spaces.png\" alt=\"\" />"
            
            # Test with special characters
            html = embeddable_html(MIME"image/jpeg"(), "file@2x.jpg", Dict{Symbol,Any}())
            @test html == "<img src=\"file@2x.jpg\" alt=\"\" />"
            
            # Test with Unicode
            html = embeddable_html(MIME"image/svg+xml"(), "图片.svg", Dict{Symbol,Any}())
            expected = "<img src=\"图片.svg\" alt=\"\" style=\"max-width: 100%; height: auto;\" />"
            @test html == expected
        end
        
        @testset "Special Characters in Attributes" begin
            # Test with quotes in alt text
            options = Dict{Symbol,Any}(:alt => "Image with \"quotes\"")
            html = embeddable_html(MIME"image/png"(), "quoted.png", options)
            @test html == "<img src=\"quoted.png\" alt=\"Image with \\\"quotes\\\"\" />"
            
            # Test with HTML entities in class
            options = Dict{Symbol,Any}(:class => "class&name")
            html = embeddable_html(MIME"image/jpeg"(), "entity.jpg", options)
            @test html == "<img src=\"entity.jpg\" alt=\"\" class=\"class&name\" />"
        end
        
        @testset "Empty and Null Values" begin
            # Test with empty filename
            html = embeddable_html(MIME"image/png"(), "", Dict{Symbol,Any}())
            @test html == "<img src=\"\" alt=\"\" />"
            
            # Test with empty options
            html = embeddable_html(MIME"video/mp4"(), "empty_opts.mp4", Dict{Symbol,Any}())
            @test html == "<video autoplay loop muted><source src=\"empty_opts.mp4\" type=\"video/mp4\"></video>"
            
            # Test with empty string values in options
            options = Dict{Symbol,Any}(:alt => "", :class => "", :style => "")
            html = embeddable_html(MIME"image/webp"(), "empty_attrs.webp", options)
            @test html == "<img src=\"empty_attrs.webp\" alt=\"\" class=\"\" style=\"\" />"
        end
    end
    
    @testset "Path Handling" begin
        @testset "Relative Paths" begin
            html = embeddable_html(MIME"image/png"(), "./assets/image.png", Dict{Symbol,Any}())
            @test html == "<img src=\"./assets/image.png\" alt=\"\" />"
            
            html = embeddable_html(MIME"video/mp4"(), "../videos/clip.mp4", Dict{Symbol,Any}())
            @test html == "<video autoplay loop muted><source src=\"../videos/clip.mp4\" type=\"video/mp4\"></video>"
        end
        
        @testset "Absolute Paths" begin
            html = embeddable_html(MIME"image/jpeg"(), "/assets/images/photo.jpg", Dict{Symbol,Any}())
            @test html == "<img src=\"/assets/images/photo.jpg\" alt=\"\" />"
        end
        
        @testset "URL Paths" begin
            html = embeddable_html(MIME"image/png"(), "https://example.com/image.png", Dict{Symbol,Any}())
            @test html == "<img src=\"https://example.com/image.png\" alt=\"\" />"
            
            html = embeddable_html(MIME"video/mp4"(), "https://cdn.example.com/video.mp4", Dict{Symbol,Any}())
            @test html == "<video autoplay loop muted><source src=\"https://cdn.example.com/video.mp4\" type=\"video/mp4\"></video>"
        end
    end
end
