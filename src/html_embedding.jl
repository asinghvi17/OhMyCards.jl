# MIME-based HTML embedding system for cover images

"""
    escape_html_attribute(s::String) -> String

Escape special characters in HTML attribute values.
Escapes double quotes to prevent breaking attribute values.
"""
function escape_html_attribute(s::String)::String
    return replace(s, "\"" => "\\\"")
end

"""
    embeddable_html(mime::MIME, filename::String, format_options::Dict{Symbol,Any}) -> String

Generate appropriate HTML embedding code based on MIME type.

This function uses MIME-based dispatch to generate the correct HTML elements for different
media types. It supports static images, animated content, and video formats with
configurable attributes.

# Arguments
- `mime::MIME`: The MIME type of the content
- `filename::String`: The filename/path to embed
- `format_options::Dict{Symbol,Any}`: Configuration options for HTML generation

# Returns
- `String`: HTML code appropriate for the MIME type

# Examples
```julia
julia> embeddable_html(MIME"image/png"(), "cover.png", Dict{Symbol,Any}())
"<img src=\"cover.png\" alt=\"\" />"

julia> embeddable_html(MIME"video/mp4"(), "animation.mp4", Dict(:autoplay => true, :loop => true))
"<video autoplay loop muted><source src=\"animation.mp4\" type=\"video/mp4\"></video>"
```
"""
function embeddable_html(mime::MIME, filename::String, format_options::Dict{Symbol,Any})::String
    # This is the main dispatch function - specific implementations below
    error("Unsupported MIME type: $mime")
end

# Static image formats - PNG, JPEG, WebP
"""
    embeddable_html(::MIME"image/png", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML `<img>` tag for PNG images.
"""
function embeddable_html(::MIME"image/png", filename::String, format_options::Dict{Symbol,Any})::String
    alt_text = escape_html_attribute(get(format_options, :alt, ""))
    class_attr = haskey(format_options, :class) ? " class=\"$(format_options[:class])\"" : ""
    style_attr = haskey(format_options, :style) ? " style=\"$(format_options[:style])\"" : ""
    
    return "<img src=\"$filename\" alt=\"$alt_text\"$class_attr$style_attr />"
end

"""
    embeddable_html(::MIME"image/jpeg", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML `<img>` tag for JPEG images.
"""
function embeddable_html(::MIME"image/jpeg", filename::String, format_options::Dict{Symbol,Any})::String
    alt_text = escape_html_attribute(get(format_options, :alt, ""))
    class_attr = haskey(format_options, :class) ? " class=\"$(format_options[:class])\"" : ""
    style_attr = haskey(format_options, :style) ? " style=\"$(format_options[:style])\"" : ""
    
    return "<img src=\"$filename\" alt=\"$alt_text\"$class_attr$style_attr />"
end

"""
    embeddable_html(::MIME"image/webp", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML `<img>` tag for WebP images.
"""
function embeddable_html(::MIME"image/webp", filename::String, format_options::Dict{Symbol,Any})::String
    alt_text = escape_html_attribute(get(format_options, :alt, ""))
    class_attr = haskey(format_options, :class) ? " class=\"$(format_options[:class])\"" : ""
    style_attr = haskey(format_options, :style) ? " style=\"$(format_options[:style])\"" : ""
    
    return "<img src=\"$filename\" alt=\"$alt_text\"$class_attr$style_attr />"
end

# SVG format with special handling
"""
    embeddable_html(::MIME"image/svg+xml", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML for SVG images with special handling options.

SVG images can be embedded as `<img>` tags or inlined. This implementation uses `<img>` tags
for consistency and security, but preserves vector scaling properties.
"""
function embeddable_html(::MIME"image/svg+xml", filename::String, format_options::Dict{Symbol,Any})::String
    alt_text = escape_html_attribute(get(format_options, :alt, ""))
    class_attr = haskey(format_options, :class) ? " class=\"$(format_options[:class])\"" : ""
    
    # SVG-specific attributes for better scaling
    svg_style = "max-width: 100%; height: auto;"
    if haskey(format_options, :style)
        # Merge custom style with SVG defaults, ensuring proper semicolon handling
        custom_style = format_options[:style]
        # Add semicolon to custom style if it doesn't end with one
        if !endswith(strip(custom_style), ";")
            custom_style = custom_style * ";"
        end
        svg_style = "$custom_style $svg_style"
    end
    
    return "<img src=\"$filename\" alt=\"$alt_text\"$class_attr style=\"$svg_style\" />"
end

# GIF format for animated images
"""
    embeddable_html(::MIME"image/gif", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML `<img>` tag for GIF images.

GIF animations are handled automatically by browsers when using `<img>` tags.
"""
function embeddable_html(::MIME"image/gif", filename::String, format_options::Dict{Symbol,Any})::String
    alt_text = escape_html_attribute(get(format_options, :alt, ""))
    class_attr = haskey(format_options, :class) ? " class=\"$(format_options[:class])\"" : ""
    style_attr = haskey(format_options, :style) ? " style=\"$(format_options[:style])\"" : ""
    
    return "<img src=\"$filename\" alt=\"$alt_text\"$class_attr$style_attr />"
end

# Video format with configurable attributes
"""
    embeddable_html(::MIME"video/mp4", filename::String, format_options::Dict{Symbol,Any}) -> String

Generate HTML `<video>` tag for MP4 videos with configurable attributes.

# Supported format_options:
- `:autoplay::Bool` - Whether video should autoplay (default: true)
- `:loop::Bool` - Whether video should loop (default: true)  
- `:muted::Bool` - Whether video should be muted (default: true)
- `:controls::Bool` - Whether to show video controls (default: false)
- `:class::String` - CSS class to apply
- `:style::String` - CSS style to apply
"""
function embeddable_html(::MIME"video/mp4", filename::String, format_options::Dict{Symbol,Any})::String
    # Build video attributes based on configuration
    attributes = String[]
    
    # Default video attributes for cover images (autoplay, loop, muted)
    if get(format_options, :autoplay, true)
        push!(attributes, "autoplay")
    end
    
    if get(format_options, :loop, true)
        push!(attributes, "loop")
    end
    
    if get(format_options, :muted, true)
        push!(attributes, "muted")
    end
    
    if get(format_options, :controls, false)
        push!(attributes, "controls")
    end
    
    # Add CSS class and style if provided
    if haskey(format_options, :class)
        push!(attributes, "class=\"$(format_options[:class])\"")
    end
    
    if haskey(format_options, :style)
        push!(attributes, "style=\"$(format_options[:style])\"")
    end
    
    # Join attributes with spaces
    attrs_str = isempty(attributes) ? "" : " " * join(attributes, " ")
    
    return "<video$attrs_str><source src=\"$filename\" type=\"video/mp4\"></video>"
end

# Convenience function that works with CoverImageConfig
"""
    embeddable_html(mime::MIME, filename::String, config::CoverImageConfig) -> String

Generate HTML embedding code using CoverImageConfig for format options.

This convenience function extracts relevant options from CoverImageConfig and converts
them to the format_options dictionary expected by the main embeddable_html function.
"""
function embeddable_html(mime::MIME, filename::String, config::CoverImageConfig)::String
    # Convert CoverImageConfig to format_options dictionary
    format_options = Dict{Symbol,Any}(
        :autoplay => config.video_autoplay,
        :loop => config.video_loop,
        :muted => config.video_muted,
        :controls => config.video_controls
    )
    
    return embeddable_html(mime, filename, format_options)
end