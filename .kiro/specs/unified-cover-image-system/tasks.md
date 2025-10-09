why is .x# Implementation Plan

- [x] 1. Create core data structures and configuration system
  - Define `CoverImageConfig` struct with all configuration options for dimensions, formats, and HTML embedding
  - Create `CoverImageResult` data structure with MIME type field
  - Define custom exception types for error handling
  - Write unit tests for configuration validation and data structure creation
  - _Requirements: 2.1, 2.3, 2.4, 2.5, 2.6_

- [x] 2. Implement MIME-based format detection system
  - Create `detect_format(filename)` function that returns appropriate MIME type based on file extension
  - Define `MIME_MAPPING` dictionary for supported formats (PNG, JPEG, WebP, SVG, GIF, MP4)
  - Add fallback to PNG MIME type for unknown extensions
  - Write unit tests for format detection with various file extensions and edge cases
  - _Requirements: 2.2, 2.4, 4.1, 4.2, 4.3_

- [x] 3. Build MIME-based HTML embedding system
  - Create `embeddable_html(::MIME, filename, format_options)` function with MIME dispatch
  - Implement HTML generation for image MIME types (`MIME"image/png"`, `MIME"image/jpeg"`, etc.)
  - Implement HTML generation for video MIME types (`MIME"video/mp4"`) with configurable attributes
  - Add support for SVG-specific handling and GIF animation
  - Write unit tests for HTML generation across all supported MIME types
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [x] 4. Define content conversion interface
  - Define `convert_to_format(content, mime::MIME, config)` function signature as the standard interface
  - Document the expected behavior and return type (Vector{UInt8})
  - Create base error handling for unsupported content/MIME combinations
  - Add basic tests for the interface (error cases, not actual conversions)
  - Note: Actual conversion implementations will be done in extension-specific tasks (7-9)
  - _Requirements: 1.1, 1.3, 1.4, 3.1, 3.2, 3.3_

- [x] 5. Implement path generation and file management
  - Create consistent path normalization across platforms and Documenter configurations
  - Implement content-based filename generation using hash functions
  - Add support for different Documenter setups (prettyurls, etc.)
  - Handle file writing with proper error handling and logging
  - Write unit tests for path generation and file operations
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 5.1 Refactor test suite into separate files
  - Split `./test/runtests.jl` into separate test files organized by functionality
  - Create `./test/test_types.jl` for CoverImageConfig, CoverImageResult, and exception types tests
  - Create `./test/test_format_detection.jl` for format detection and MIME mapping tests
  - Create `./test/test_html_embedding.jl` for HTML generation tests
  - Create `./test/test_content_conversion.jl` for content conversion interface tests
  - Update `./test/runtests.jl` to include all test files
  - Ensure all tests still pass after refactoring
  - Note: `./test/test_path_generation.jl` already exists and should remain separate

- [x] 6. Create orchestrating function for complete pipeline
  - Create `process_cover_image` function that coordinates all components
  - Integrate format detection, conversion, path generation, and HTML generation
  - Function should accept page, doc, content, and config parameters
  - Return `CoverImageResult` with all generated artifacts
  - Write integration tests for complete processing pipeline
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 7. Update Colors extension to use new MIME-based system
  - Implement `convert_to_format` methods in `./ext/OhMyCardsColorsExt.jl` for `AbstractMatrix{<: Colorant}` with different MIME types
  - Add support for PNG, JPEG, and WebP conversion from color matrices
  - Update `get_image_url` and `set_cover_to_image!` to use new MIME-based processing
  - Maintain backward compatibility during transition
  - Write tests in `./test/test_colors_ext.jl` to ensure Colors extension works with new system
  - _Requirements: 1.1, 1.2, 3.1, 3.2_

- [x] 8. Update Plots extension to use new MIME-based system
  - Implement `convert_to_format` methods in `./ext/OhMyCardsPlotsExt.jl` for `Plots.Plot` and `Plots.Subplot` with different MIME types
  - Add support for PNG, SVG, and other formats supported by Plots.jl
  - Update extension to use centralized MIME-based processing
  - Remove duplicated image processing logic
  - Write tests in `./test/test_plots_ext.jl` to ensure Plots extension works with new system
  - _Requirements: 1.1, 1.2, 3.1, 3.2_

- [x] 9. Update Makie extension to use new MIME-based system
  - Implement `convert_to_format` methods in `./ext/OhMyCardsMakieExt.jl` for `Makie.FigureLike` types with different MIME types
  - Add support for PNG, SVG, and other formats supported by Makie.jl
  - Fix existing path generation inconsistencies using new MIME-based system
  - Update error handling to use centralized approach
  - Write tests in `./test/test_makie_ext.jl` to ensure Makie extension works with new system
  - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2_

- [x] 10. Integrate new MIME-based system into cardmeta processing
  - Update `./src/cardmeta.jl` to use MIME-based `convert_to_format` and `embeddable_html` functions
  - Modify cover detection logic to work with new MIME dispatch system
  - Update HTML injection to use `embeddable_html` with detected MIME types
  - Ensure configuration is properly passed through the MIME-based system
  - Write integration tests in `./test/test_cardmeta_integration.jl` for cardmeta processing with new system
  - _Requirements: 1.1, 1.2, 4.1, 4.2, 4.3_

- [ ] 11. Add comprehensive error handling and logging
  - Implement error handling throughout the processing pipeline
  - Add appropriate logging for debugging and user feedback
  - Create fallback mechanisms for processing failures
  - Ensure errors don't break documentation build process
  - Write tests for error scenarios and recovery mechanisms
  - _Requirements: 1.4, 5.4_

- [ ] 12. Create end-to-end integration tests
  - Write tests that exercise complete pipeline with real plotting objects
  - Test with different Documenter configurations and output formats
  - Verify backward compatibility with existing documentation projects
  - Test performance characteristics compared to current implementation
  - Validate generated HTML and file paths in realistic scenarios
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 4.1, 4.2, 5.1, 5.2, 5.3_

- [ ] 13. Standardize path notation to use relative paths with `./` prefix
  - Audit all file path references in the codebase (source, tests, extensions)
  - Update path construction to use `joinpath(".", ...)` pattern consistently
  - Update documentation and comments to use `./` prefix for file references
  - Ensure all `joinpath` calls start with `"."` for relative paths
  - Update any hardcoded path strings to use relative notation
  - Verify tests still pass after path notation updates
  - _Requirements: 6.1, 6.2, 6.3, 6.4_