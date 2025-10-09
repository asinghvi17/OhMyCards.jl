# Requirements Document

## Introduction

The current cover image handling system in OhMyCards has duplicated logic across multiple extensions (Plots, Makie, Colors) with inconsistent behavior, hard-coded sizing, and limited format support. This feature will create a unified, configurable cover image processing system that eliminates code duplication, provides consistent behavior, and offers flexible configuration options.

## Requirements

### Requirement 1

**User Story:** As a developer using OhMyCards, I want a unified cover image processing system so that all plotting backends behave consistently and maintainably.

#### Acceptance Criteria

1. WHEN any supported figure type is processed THEN the system SHALL use a single, centralized image processing pipeline
2. WHEN processing images from different backends (Plots, Makie, Colors) THEN the system SHALL produce consistent file paths and naming conventions
3. WHEN an error occurs during image processing THEN the system SHALL handle it consistently across all backends
4. IF image processing fails THEN the system SHALL provide a fallback mechanism with appropriate error logging

### Requirement 2

**User Story:** As a documentation author, I want configurable image dimensions and formats so that I can optimize cover images for different use cases.

#### Acceptance Criteria

1. WHEN configuring the system THEN users SHALL be able to specify custom image dimensions (width, height, or aspect ratio)
2. WHEN generating cover images THEN the system SHALL support multiple output formats (PNG, JPEG, WebP, SVG, GIF, MP4)
3. WHEN using lossy formats (JPEG, WebP) THEN users SHALL be able to configure quality settings
4. WHEN using vector formats (SVG) THEN the system SHALL preserve vector data when the source supports it
5. WHEN using video formats (MP4) THEN the system SHALL support animated content and video encoding parameters
6. IF no configuration is provided THEN the system SHALL use sensible defaults (600px height, PNG format)

### Requirement 3

**User Story:** As a maintainer of OhMyCards, I want a clean extension interface so that adding support for new plotting backends requires minimal code duplication.

#### Acceptance Criteria

1. WHEN adding support for a new plotting backend THEN developers SHALL only need to implement a single conversion function
2. WHEN implementing backend support THEN the conversion function SHALL follow a standardized interface
3. WHEN the core image processing logic changes THEN all backends SHALL automatically benefit from improvements
4. IF a backend has special requirements THEN the system SHALL allow backend-specific configuration overrides

### Requirement 4

**User Story:** As a documentation author, I want file extension-aware HTML embedding so that different media types are properly displayed in the generated documentation.

#### Acceptance Criteria

1. WHEN embedding static images (PNG, JPEG, WebP) THEN the system SHALL generate `<img>` tags with appropriate attributes
2. WHEN embedding animated content (GIF, MP4) THEN the system SHALL generate appropriate HTML elements (`<img>` for GIF, `<video>` for MP4)
3. WHEN embedding vector graphics (SVG) THEN the system SHALL generate `<img>` tags or inline SVG based on configuration
4. WHEN generating video elements THEN the system SHALL include appropriate attributes (autoplay, loop, muted, controls)
5. IF the file extension is unrecognized THEN the system SHALL default to `<img>` tag with appropriate fallback handling

### Requirement 5

**User Story:** As a user generating documentation, I want reliable path generation so that cover images are always accessible regardless of the documentation structure.

#### Acceptance Criteria

1. WHEN generating image paths THEN the system SHALL normalize paths consistently across all platforms
2. WHEN using different Documenter configurations (prettyurls, etc.) THEN the system SHALL generate correct relative paths
3. WHEN images are referenced in HTML THEN the paths SHALL be valid and accessible
4. IF path generation fails THEN the system SHALL log appropriate errors and provide fallback behavior

### Requirement 6

**User Story:** As a developer working with the OhMyCards codebase, I want all file paths to use relative path notation so that code is portable and follows Julia best practices.

#### Acceptance Criteria

1. WHEN referencing files in the codebase THEN all paths SHALL begin with `./` to indicate relative paths
2. WHEN constructing file paths programmatically THEN the system SHALL use `joinpath` with relative components starting with `./`
3. WHEN documenting file locations THEN documentation SHALL use relative path notation beginning with `./`
4. IF absolute paths are needed internally THEN they SHALL be constructed from relative paths at runtime