# Design Document

## Overview

The unified cover image system will replace the current duplicated image processing logic across extensions with a centralized, configurable system. The design introduces a `CoverImageProcessor` core component that handles format detection, conversion, and HTML embedding, while maintaining backward compatibility with existing extensions.

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────────┐
│                    CoverImageProcessor                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ FormatDetector  │  │ ImageConverter  │  │ HTMLEmitter │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                Extension Interface Layer                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ PlotsExt    │  │ MakieExt    │  │ ColorsExt + Others  │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Processing Pipeline

1. **Format Detection**: Determine optimal output format based on source content and configuration
2. **Content Conversion**: Convert source object to raw image/video data
3. **Format Processing**: Apply format-specific processing (resizing, compression, encoding)
4. **File Generation**: Write processed content to disk with appropriate naming
5. **HTML Generation**: Create format-appropriate HTML embedding code

## Components and Interfaces

### File Organization

Core system components are organized as follows:
- **Core types and config**: `./src/types.jl`
- **Format detection**: `./src/format_detection.jl`
- **HTML embedding**: `./src/html_embedding.jl`
- **Content conversion interface**: `./src/content_conversion.jl`
- **Path generation**: `./src/path_generation.jl`
- **Main processor**: `./src/processor.jl`
- **Extensions**: `./ext/OhMyCards*Ext.jl`
- **Tests**: `./test/test_*.jl`

### CoverImageProcessor

The central processor that orchestrates the entire pipeline (defined in `./src/processor.jl`):

```julia
struct CoverImageProcessor
    config::CoverImageConfig
    format_detector::FormatDetector
    converter_registry::Dict{Type, Function}
end
```

**Key Methods:**
- `process_cover(processor, meta, page, doc, content)`: Main processing entry point
- `register_converter!(processor, type, converter_fn)`: Register backend-specific converters
- `get_image_url(processor, page, doc, content)`: Generate image URL for inline display

### CoverImageConfig

Configuration structure for customizing image processing (defined in `./src/types.jl`):

```julia
@kwdef struct CoverImageConfig
    # Dimensions
    target_height::Union{Int, Nothing} = 600
    target_width::Union{Int, Nothing} = nothing
    maintain_aspect_ratio::Bool = true
    
    # Format preferences
    preferred_format::Union{String, Nothing} = nothing  # "png", "jpeg", "webp", "svg", "gif", "mp4"
    fallback_format::String = "png"
    
    # Quality settings
    jpeg_quality::Int = 85
    webp_quality::Int = 80
    
    # Video settings
    mp4_fps::Int = 30
    mp4_duration::Union{Float64, Nothing} = nothing  # Auto-detect if nothing
    
    # HTML embedding
    video_autoplay::Bool = true
    video_loop::Bool = true
    video_muted::Bool = true
    video_controls::Bool = false
    
    # Path generation
    filename_prefix::String = ""
    use_content_hash::Bool = true
end
```

### Format Detection System

Uses Julia's built-in MIME system for format detection and handling (implemented in `./src/format_detection.jl`):

```julia
# Core format detection function
function detect_format(filename::String)::MIME
    ext = lowercase(splitext(filename)[2])
    return get(MIME_MAPPING, ext, MIME"image/png"())
end

const MIME_MAPPING = Dict(
    ".png" => MIME"image/png"(),
    ".jpg" => MIME"image/jpeg"(),
    ".jpeg" => MIME"image/jpeg"(),
    ".webp" => MIME"image/webp"(),
    ".svg" => MIME"image/svg+xml"(),
    ".gif" => MIME"image/gif"(),
    ".mp4" => MIME"video/mp4"()
)
```

**Detection Logic:**
- File extension-based MIME type detection
- Fallback to PNG for unknown extensions
- User configuration can override detected MIME type
- Content-based format recommendation for optimal output

### Content Conversion System

The content conversion system provides a unified interface for converting plotting objects to image bytes. The interface is defined centrally in `./src/content_conversion.jl`, but actual implementations are extension-specific since each plotting library has its own conversion methods.

**Interface Definition:**

```julia
"""
    convert_to_format(content, mime::MIME, config::CoverImageConfig) -> Vector{UInt8}

Convert content to the specified MIME format.

This is the standard interface that all extensions should implement. Each extension
provides methods for their specific content types (Plots.Plot, Makie.Figure, etc.).

# Arguments
- `content`: The content to convert (plot, figure, color matrix, etc.)
- `mime::MIME`: Target MIME type (e.g., MIME"image/png"())
- `config::CoverImageConfig`: Configuration for conversion (quality, dimensions, etc.)

# Returns
- `Vector{UInt8}`: Raw bytes of the converted image/video

# Throws
- `UnsupportedFormatError`: If the content type doesn't support the requested MIME type
- `ConversionError`: If conversion fails for any reason
"""
function convert_to_format(content, mime::MIME, config::CoverImageConfig)::Vector{UInt8}
    throw(UnsupportedFormatError(typeof(content), string(mime)))
end
```

**Extension-Specific Implementations:**

Each extension implements conversion methods for their content types. Examples:

```julia
# In ./ext/OhMyCardsPlotsExt.jl - implemented in Task 8
function convert_to_format(plot::Plots.Plot, ::MIME"image/png", config::CoverImageConfig)::Vector{UInt8}
    # Use Plots.jl's savefig with PNG backend
end

# In ./ext/OhMyCardsMakieExt.jl - implemented in Task 9
function convert_to_format(fig::Makie.Figure, ::MIME"image/svg+xml", config::CoverImageConfig)::Vector{UInt8}
    # Use Makie's save with SVG backend
end

# In ./ext/OhMyCardsColorsExt.jl - implemented in Task 7
function convert_to_format(image::AbstractMatrix{<:Colorant}, ::MIME"image/jpeg", config::CoverImageConfig)::Vector{UInt8}
    # Use ImageIO with JPEG quality from config
end
```

**Design Rationale:**

- **Interface-only approach**: The core system defines the interface and error handling, but doesn't implement conversions
- **Extension ownership**: Each extension knows best how to convert its own types
- **MIME dispatch**: Allows extensions to support different formats naturally
- **Configuration passing**: Quality settings and dimensions are passed through config
- **Lazy implementation**: Conversions are implemented only when updating each extension (Tasks 7-9)

### HTML Embedding System

Uses MIME-based dispatch for generating appropriate HTML (implemented in `./src/html_embedding.jl`):

```julia
# Main HTML generation function with MIME dispatch
function embeddable_html(mime::MIME, filename::String, format_options::Dict{Symbol,Any})::String
    # Dispatches to specific MIME type handlers
end

# Specific implementations for each MIME type
function embeddable_html(::MIME"image/png", filename::String, options::Dict)::String
    return "<img src=\"$filename\" alt=\"\" />"
end

function embeddable_html(::MIME"image/jpeg", filename::String, options::Dict)::String
    return "<img src=\"$filename\" alt=\"\" />"
end

function embeddable_html(::MIME"video/mp4", filename::String, options::Dict)::String
    attrs = join([
        get(options, :autoplay, true) ? "autoplay" : "",
        get(options, :loop, true) ? "loop" : "",
        get(options, :muted, true) ? "muted" : "",
        get(options, :controls, false) ? "controls" : ""
    ], " ")
    return "<video $attrs><source src=\"$filename\" type=\"video/mp4\"></video>"
end
```

**HTML Generation Rules:**
- **Static Images** (PNG, JPEG, WebP): `<img>` tags via MIME dispatch
- **SVG**: `<img>` tags with SVG-specific handling
- **GIF**: `<img>` tags (browsers handle animation)
- **MP4**: `<video>` tags with configurable attributes

## Data Models

### CoverImageResult

Result structure containing all processing artifacts (defined in `./src/types.jl`):

```julia
struct CoverImageResult
    file_path::String
    relative_url::String
    mime_type::MIME
    html_embed::String
    metadata::Dict{Symbol, Any}
end
```

## Path Notation Standards

### Relative Path Convention

All file paths in the codebase follow a consistent relative path notation:

**Rules:**
1. **Relative paths start with `./`**: All file references use `./` prefix to indicate relative paths
2. **Use `joinpath` for construction**: Build paths using `joinpath(".", "dir", "file.ext")` 
3. **Examples:**
   - Source files: `./src/processor.jl`
   - Test files: `./test/test_colors_ext.jl`
   - Extension files: `./ext/OhMyCardsColorsExt.jl`
   - Build output: `./build/examples/image.png`

**Rationale:**
- Explicit relative path notation improves code clarity
- Consistent with Julia best practices
- Makes file references portable across different working directories
- Easier to distinguish relative from absolute paths in code review

**Implementation:**
```julia
# Good: Explicit relative path
source_file = joinpath(".", "src", "processor.jl")

# Good: Building relative paths
test_dir = joinpath(".", "test")
test_file = joinpath(test_dir, "test_colors_ext.jl")

# Avoid: Implicit relative paths without ./
source_file = joinpath("src", "processor.jl")  # Less clear
```



## Error Handling

### Error Types

Custom exception types for error handling (defined in `./src/types.jl`):

```julia
abstract type CoverImageError <: Exception end

struct UnsupportedFormatError <: CoverImageError
    content_type::Type
    requested_format::String
end

struct ConversionError <: CoverImageError
    content_type::Type
    format::String
    original_error::Exception
end

struct PathGenerationError <: CoverImageError
    reason::String
end
```

### Error Handling Strategy

1. **Graceful Degradation**: If preferred format fails, attempt fallback format
2. **Logging**: All errors logged with context (page, content type, attempted format)
3. **Fallback Content**: Generate placeholder image/HTML for critical failures
4. **Error Propagation**: Non-critical errors don't stop documentation build

## Testing Strategy

### Unit Tests

1. **Format Detection Tests** (`./test/test_format_detection.jl`)
   - Test format detection for various content types
   - Verify configuration override behavior
   - Test edge cases (unknown types, conflicting preferences)

2. **Conversion Interface Tests** (`./test/test_content_conversion.jl`)
   - Test that the base interface throws appropriate errors for unsupported types
   - Verify error types and messages
   - Extension-specific conversion tests are in `./test/test_*_ext.jl` files (Tasks 7-9)

3. **HTML Generation Tests** (`./test/test_html_embedding.jl`)
   - Verify correct HTML for each format type
   - Test configuration option effects
   - Validate HTML structure and attributes

4. **Path Generation Tests** (`./test/test_path_generation.jl`)
   - Test path normalization and generation
   - Verify relative path construction with `./` prefix
   - Test cross-platform compatibility

5. **Type and Config Tests** (`./test/test_types.jl`)
   - Test CoverImageConfig validation
   - Test CoverImageResult structure
   - Test custom exception types

### Integration Tests

1. **End-to-End Processing** (`./test/test_end_to_end.jl`)
   - Test complete pipeline with real plotting objects
   - Verify file generation and path correctness
   - Test with different Documenter configurations

2. **Extension Compatibility** (`./test/test_colors_ext.jl`, `./test/test_plots_ext.jl`, `./test/test_makie_ext.jl`)
   - Ensure backward compatibility with existing extensions
   - Test migration path from old to new system
   - Verify performance characteristics

3. **Cardmeta Integration** (`./test/test_cardmeta_integration.jl`)
   - Test integration with cardmeta processing
   - Verify cover detection and HTML injection
   - Test configuration passing through the system

### Performance Tests

1. **Processing Speed**: Benchmark against current implementation
2. **Memory Usage**: Monitor memory consumption during conversion
3. **File Size**: Compare output file sizes across formats

## Migration Strategy

### Phase 1: Core Infrastructure (Tasks 1-6)
- Implement data structures and configuration system
- Add MIME-based format detection
- Create HTML embedding system with MIME dispatch
- Define conversion interface (signature and error handling only)
- Implement path generation and file management
- Build central `CoverImageProcessor` orchestrator

### Phase 2: Extension Migration (Tasks 7-9)
- Update Colors extension (`./ext/OhMyCardsColorsExt.jl`) with `convert_to_format` implementations
- Update Plots extension (`./ext/OhMyCardsPlotsExt.jl`) with `convert_to_format` implementations
- Update Makie extension (`./ext/OhMyCardsMakieExt.jl`) with `convert_to_format` implementations
- Each extension implements conversions for formats they support
- Maintain backward compatibility during transition
- Add extension-specific tests in `./test/test_*_ext.jl` files

### Phase 3: Integration and Polish (Tasks 10-13)
- Integrate new system into cardmeta processing (`./src/cardmeta.jl`)
- Add comprehensive error handling and logging
- Create end-to-end integration tests
- Verify backward compatibility with existing projects
- Standardize all path notation to use `./` prefix for relative paths

### Backward Compatibility

- Existing `get_image_url` and `set_cover_to_image!` functions remain functional
- Extensions can opt-in to new system gradually
- Configuration provides sensible defaults matching current behavior