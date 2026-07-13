module OhMyCardsDocumenterVitepressExt

# Wires VitepressGallery's search JS into a DocumenterVitepress build: ship it as a
# `public/` asset + `<head>` script (Vue escapes/never runs body `<script>`s).
# Both hooks key off the `ExampleConfig` plugin, which DocumenterVitepress walks.

import OhMyCards
import DocumenterVitepress

# Copy `assets/` into Vitepress `public/`, serving `<base>/omc_gallery_search.js`.
DocumenterVitepress.vitepress_assets(::OhMyCards.ExampleConfig) =
    String[OhMyCards._gallery_assets_dir()]

# Add a base-aware `<head>` `<script src>` entry that loads the gallery script.
DocumenterVitepress.vitepress_config_transform(::OhMyCards.ExampleConfig, config::String) =
    OhMyCards._inject_gallery_head_script(config)

end # module
