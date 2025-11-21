require 'open-uri'
require 'base64'
require 'tempfile'
require 'mini_magick'

module CrossDoc

  # represents a reference to an image used in a document
  class ImageRef
    include CrossDoc::Fields

    def initialize(attrs={})
      assign_fields attrs
    end

    simple_fields %i(src hash)

    attr_reader :image, :is_svg

    DATA_URL_REGEXP = /^data:(?<type>[^;]+)(?<base64>;base64)?,(?<data>.*)$/

    def download(skip_resize: false)
      @image = MiniMagic::Image.read download_raw_image
      @is_svg = img.type == 'SVG'
      @image.combine_options do |i|
        if @is_svg || skip_resize
          i.quality 80
          i.geometry image_width(img.size)
          i.background '#FFFFFF'
          i.alpha 'remove'
        end
        i.auto_orient if img.type == 'JPEG'
      end
    end

    # decrease width as image file size increases to decrease final pdf size
    # starts from 2 x page width (1024px)
    # 1MB -> 963px, 6MB -> 658px
    def image_width(file_size)
      scale_amount = (file_size/1024/16)
      1024 - scale_amount
    end

    # returns a hash (with :width and :height keys) giving the natural size of the images
    def dimensions
      @image.size => [width, height]
      { width: width, height: height }
    end

    def dispose = @io&.close

    # Singleton IO wrapper
    def io = (@io ||= StringIO.new(@image.to_blob))

    private

    def download_raw_image()
      # Parse data fields
      data_url_match = DATA_URL_REGEXP.match @src
      image_url = URL.parse @src

      if data_url_match.present?
        data = data_url_match[:data]
        if data_url_match[:base64].present?
          Base64.decode64 data
        else
          CGI.unescape data
        end
      elsif [URI::HTTP, URI::HTTPS, URI::FTP].include? image_url.class
        image_url.open.read
      elsif image_url.is_a? URI::File
        raise 'Cannot use file:/// URLs in embedded images'
      else # Use local file path
        File.open(@src).read
      end
    end
  end

  # represents a single node in the DOM
  class Node
    include CrossDoc::Fields

    def initialize(attrs={})
      assign_fields attrs
    end

    simple_fields %i[id tag text src hash list_style list_level start input_type input_value input_possible]

    object_field :background, Background

    object_field :box, Box

    object_field :border, Border

    object_field :font, Font

    object_field :padding, Margin

    array_field :children, Node

    def to_s
      downcase_tag = @tag.to_s.downcase
      if @text.present?
        "<#{downcase_tag}>#{@text.to_s}</#{downcase_tag}>"
      elsif @children.present?
        child_noun = @children.length > 1 ? "children" : "child"
        "<#{downcase_tag}>...</#{downcase_tag}> (#{@children.length} #{child_noun})"
      else
        "<#{downcase_tag}>"
      end
    end

  end


  class Page
    include CrossDoc::Fields

    def initialize(attrs={})
      assign_fields attrs
    end

    array_field :children, Node

  end


  class Document
    include CrossDoc::Fields

    simple_fields %i(page_orientation)

    object_field :page_width, Integer
    object_field :page_height, Integer
    object_field :page_margin, Margin

    array_field :pages, Page

    object_field :header, Node
    object_field :footer, Node

    hash_field :images, ImageRef

    def initialize(attrs)
      if attrs.instance_of? String
        attrs = JSON.parse attrs
      end
      assign_fields attrs
      unless @page_margin
        @page_margin = Margin.new
      end
    end

    def self.from_file(path)
      File.open(path, 'r') do |file|
        return Document.new JSON.parse(file.read)
      end
    end


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

    # returns the page dimensions (width/height hash) for the given page size and orientation, or nil if one or more arguments are incorrect
    # current possible page sizes are 'us-letter' and 'us-legal'
    # orientations are 'portrait' or 'landscape'
    def self.get_dimensions(size, orientation)
      portrait_size = @portrait_dimensions[size.to_s.gsub('-', '_').to_sym]
      unless portrait_size
        return nil
      end
      if orientation && orientation.to_s == 'landscape'
        return {width: portrait_size[:height], height: portrait_size[:width]}
      end
      portrait_size
    end

  end

end
