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
      elsif @src.index('data:image/png;') == 0
        @is_svg = false
        raw = Base64.decode64 @src.gsub('data:image/png;base64,', '')
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

    simple_fields %i(orientation size page_margin)

    object_field :padding, Margin

    object_field :box, Box

    array_field :children, Node


    ## Page Margins

    @page_margin_sizes = {
        '0.5in' => 36,
        '0.75in' => 54,
        '1.0in' => 72
    }

    def self.page_margin_size(margin)
      @page_margin_sizes[margin] || @page_margin_sizes.values.first
    end


    ## Paper Sizes

    @portrait_dimensions = {
        us_letter: {width: 612, height: 792},
        us_legal: {width: 612, height: 1008}
    }

    # returns the page dimensions (width/height hash) for the given page options (size and orientation), or nil if one or more arguments are incorrect
    # current possible page sizes are 'us-letter' and 'us-legal'
    # orientations are 'portrait' or 'landscape'
    def self.get_dimensions(options)
      portrait_size = @portrait_dimensions[options[:size].gsub('-', '_').to_sym]
      unless portrait_size
        return nil
      end
      if options[:orientation].to_s == 'landscape'
        return {width: portrait_size[:height], height: portrait_size[:width]}
      end
      portrait_size
    end

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
