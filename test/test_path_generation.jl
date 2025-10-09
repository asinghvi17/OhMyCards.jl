using Test
using OhMyCards
using Documenter

@testset "Path Generation" begin
    
    @testset "generate_filename" begin
        # Test basic filename generation
        bytes = UInt8[1, 2, 3, 4, 5]
        filename = OhMyCards.generate_filename(bytes, "png")
        @test endswith(filename, ".png")
        @test !startswith(filename, ".")
        @test length(filename) > 4  # hash + ".png"
        
        # Test with leading dot in extension
        filename_with_dot = OhMyCards.generate_filename(bytes, ".png")
        @test filename == filename_with_dot
        
        # Test with prefix
        filename_with_prefix = OhMyCards.generate_filename(bytes, "png", prefix="cover_")
        @test startswith(filename_with_prefix, "cover_")
        @test endswith(filename_with_prefix, ".png")
        
        # Test that same content produces same filename (deterministic)
        filename2 = OhMyCards.generate_filename(bytes, "png")
        @test filename == filename2
        
        # Test that different content produces different filename
        different_bytes = UInt8[5, 4, 3, 2, 1]
        different_filename = OhMyCards.generate_filename(different_bytes, "png")
        @test filename != different_filename
        
        # Test various extensions
        for ext in ["jpg", "jpeg", "webp", "svg", "gif", "mp4"]
            fn = OhMyCards.generate_filename(bytes, ext)
            @test endswith(fn, ".$ext")
        end
    end
    
    @testset "has_prettyurls and generate_relative_path with real Documenter" begin
        # Create a temporary directory for test documentation
        mktempdir() do tmpdir
            # Create a minimal markdown file
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n\nTest content")
            write(joinpath(src_dir, "page.md"), "# Page\n\nPage content")
            
            # Test with prettyurls=false
            doc_no_pretty = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build_no_pretty"),
                format = Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            @test OhMyCards.has_prettyurls(doc_no_pretty) == false
            
            # Test with prettyurls=true
            doc_pretty = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build_pretty"),
                format = Documenter.HTML(prettyurls=true, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            @test OhMyCards.has_prettyurls(doc_pretty) == true
            
            # Test generate_relative_path with real page objects
            # Get a page from the document
            page_no_pretty = doc_no_pretty.blueprint.pages["page.md"]
            filename = "test_image.png"
            
            path_no_pretty = OhMyCards.generate_relative_path(page_no_pretty, doc_no_pretty, filename)
            @test occursin(filename, path_no_pretty)
            @test !occursin("//", path_no_pretty)
            
            page_pretty = doc_pretty.blueprint.pages["page.md"]
            path_pretty = OhMyCards.generate_relative_path(page_pretty, doc_pretty, filename)
            @test occursin(filename, path_pretty)
            @test !occursin("//", path_pretty)
            
            # With prettyurls, the path should be relative (../) since HTML is in page/index.html
            @test startswith(path_pretty, "..")
        end
    end
    
    @testset "write_image_file" begin
        # Test writing to a temporary file
        mktempdir() do tmpdir
            filepath = joinpath(tmpdir, "test_image.png")
            content = UInt8[137, 80, 78, 71, 13, 10, 26, 10]  # PNG header bytes
            
            # Should write successfully
            OhMyCards.write_image_file(filepath, content)
            @test isfile(filepath)
            @test read(filepath) == content
            
            # Test writing to nested directory (should create parent dirs)
            nested_path = joinpath(tmpdir, "subdir", "nested", "image.png")
            OhMyCards.write_image_file(nested_path, content)
            @test isfile(nested_path)
            @test read(nested_path) == content
            
            # Test overwriting existing file
            new_content = UInt8[1, 2, 3, 4]
            OhMyCards.write_image_file(filepath, new_content)
            @test read(filepath) == new_content
        end
        
        # Test error handling for invalid path
        @test_throws Exception OhMyCards.write_image_file("/invalid/path/that/cannot/exist/image.png", UInt8[1, 2, 3])
    end
    
    @testset "generate_and_write_image with real Documenter" begin
        mktempdir() do tmpdir
            # Create a minimal documentation setup
            src_dir = joinpath(tmpdir, "src")
            mkpath(src_dir)
            write(joinpath(src_dir, "index.md"), "# Test\n")
            write(joinpath(src_dir, "test.md"), "# Test Page\n")
            
            # Create document with prettyurls=false
            doc = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build"),
                format = Documenter.HTML(prettyurls=false, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            page = doc.blueprint.pages["test.md"]
            content_bytes = UInt8[137, 80, 78, 71, 13, 10, 26, 10]
            
            # Test without prefix
            fs_path, rel_url = OhMyCards.generate_and_write_image(page, doc, content_bytes, "png")
            
            @test isfile(fs_path)
            @test read(fs_path) == content_bytes
            @test endswith(fs_path, ".png")
            @test endswith(rel_url, ".png")
            
            # Test with prefix
            fs_path2, rel_url2 = OhMyCards.generate_and_write_image(page, doc, content_bytes, "png", prefix="cover_")
            
            @test isfile(fs_path2)
            @test occursin("cover_", basename(fs_path2))
            @test occursin("cover_", rel_url2)
            
            # Test with prettyurls=true
            doc_pretty = makedocs(
                sitename = "Test",
                source = src_dir,
                build = joinpath(tmpdir, "build_pretty"),
                format = Documenter.HTML(prettyurls=true, edit_link=nothing),
                debug = true,
                warnonly = true
            )
            
            page_pretty = doc_pretty.blueprint.pages["test.md"]
            fs_path3, rel_url3 = OhMyCards.generate_and_write_image(page_pretty, doc_pretty, content_bytes, "png")
            
            @test isfile(fs_path3)
            @test startswith(rel_url3, "..")  # With prettyurls, path is relative (../)
        end
    end
    
end
