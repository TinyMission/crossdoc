require 'crossdoc/version'

module CrossDoc
  require 'crossdoc/geom'
  require 'crossdoc/font_metrics'
  require 'crossdoc/tree'
  require 'crossdoc/pdf_render'
  require 'crossdoc/builder'
  require 'crossdoc/paginator'
  require 'crossdoc/markdown_builder'
  require 'crossdoc/converter'

  if defined? Rails
    module Rails
      class Engine < ::Rails::Engine
      end
    end
  end

end
