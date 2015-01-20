require 'crossdoc/version'

module CrossDoc
  require 'crossdoc/geom'
  require 'crossdoc/tree'
  require 'crossdoc/render'

  if defined? Rails
    module Rails
      class Engine < ::Rails::Engine
      end
    end
  end

end
