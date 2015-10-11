require 'crossdoc/version'

module CrossDoc
  Prawn::Font::AFM.hide_m17n_warning = true
  require 'crossdoc/geom'
  require 'crossdoc/tree'
  require 'crossdoc/pdf_render'

  if defined? Rails
    module Rails
      class Engine < ::Rails::Engine
      end
    end
  end

end
