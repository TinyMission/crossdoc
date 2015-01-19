require 'crossdoc/version'

module CrossDoc
  require 'crossdoc/geom'
  require 'crossdoc/tree'
  require 'crossdoc/render'

  module Rails
    class Engine < ::Rails::Engine
    end
  end
end
