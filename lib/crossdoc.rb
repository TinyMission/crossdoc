require 'crossdoc/version'

module CrossDoc
  require 'crossdoc/geom'
  require 'crossdoc/font_metrics'
  require 'crossdoc/tree'
  require 'crossdoc/pdf_render'
  require 'crossdoc/builder'
  require 'crossdoc/paginator'
  require 'crossdoc/editor_js_builder'
  require 'crossdoc/markdown_builder'
  require 'crossdoc/converter'
  require 'crossdoc/prawn_monkey_patches'

  if defined? Rails
    module Rails
      class Engine < ::Rails::Engine
      end
    end
  end

end
