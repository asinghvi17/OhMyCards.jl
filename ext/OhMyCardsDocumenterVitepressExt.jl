module OhMyCardsDocumenterVitepressExt

# Wires the VitepressGallery client-side search JS into a DocumenterVitepress
# build. The JS cannot live in page content (Vue escapes and never runs body
# `<script>`s), so we ship it as a `public/` asset and load it from `<head>`.
#
# Both hooks key off OhMyCards' `ExampleConfig` plugin, which the consumer
# registers with `makedocs(; plugins = [..., ExampleConfig(...)])`. DocumenterVitepress
# walks every registered plugin and merges the results.

import OhMyCards
import DocumenterVitepress

# Copy `assets/`'s contents (the gallery script) into the Vitepress `public/`
# dir, so it is served at `<base>/omc_gallery_search.js`.
DocumenterVitepress.vitepress_assets(::OhMyCards.ExampleConfig) =
    String[OhMyCards._gallery_assets_dir()]

# Add a base-aware `<head>` `<script src>` entry that loads the gallery script.
DocumenterVitepress.vitepress_config_transform(::OhMyCards.ExampleConfig, config::String) =
    OhMyCards._inject_gallery_head_script(config)

end # module
