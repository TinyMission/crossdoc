require 'open-uri'
require 'base64'
require 'tempfile'

module CrossDoc

  # represents a reference to an image used in a document
  class ImageRef
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(src hash)

    attr_reader :io, :is_svg

    def download
      if @src.index('data:image/svg+xml;') == 0
        @is_svg = true
        raw = Base64.decode64 @src.gsub('data:image/svg+xml;base64,', '')
        @io = StringIO.new raw
      else
        @is_svg = false
        if @src.index('file://')==0
          @io = open(@src.gsub('file://', ''))
        else
          @io = open(@src)
        end
      end
    end

    def dispose
      if @io
        @io.close
      end
    end

  end


  # represents a single node in the DOM
  class Node
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(tag text src hash list_style input_type input_value input_possible)

    object_field :background, Background

    object_field :box, Box

    object_field :border, Border

    object_field :font, Font

    object_field :padding, Margin

    array_field :children, Node

  end


  class Page
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(width height)

    object_field :padding, Margin

    array_field :children, Node

  end


  class Document
    include CrossDoc::Fields

    array_field :pages, Page

    hash_field :images, ImageRef

    def initialize(attrs)
      assign_fields attrs
    end

    def self.from_file(path)
      File.open(path, 'r') do |file|
        return Document.new JSON.parse(file.read)
      end
    end
  end

end
