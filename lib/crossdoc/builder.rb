module CrossDoc

  # DSL for recursively creating nodes
  class NodeBuilder
    include CrossDoc::RawShadow

    raw_shadow :padding, -> {Margin.new}

    raw_shadow :box, -> {Box.new}

    raw_shadow :border

    raw_shadow :background

    raw_shadow :list_style

    raw_shadow :text

    raw_shadow :font

    raw_shadow :tag

    attr_accessor :block_orientation, :weight, :min_height, :margin

    def initialize(doc_builder, raw)
      @doc_builder = doc_builder

      @block_orientation = raw[:block_orientation] ? raw[:block_orientation].to_sym : :vertical
      raw.delete :block_orientation

      @weight = raw[:weight] || 1.0
      raw.delete :weight

      init_raw raw

      if @raw.has_key? :src
        self.image_src @raw[:src]
        @raw.delete :src
      end

      @child_builders = []

      @min_height = 0

      # we don't store the margin in @raw because it's not actually part of the CrossDoc schema
      @margin = Margin.new
    end

    def push_min_height(h)
      if h > @min_height
        @min_height = h
      end
    end

    def default_font(adjustments)
      self.font = CrossDoc::Font.default adjustments
    end

    def border_all(s)
      side = CrossDoc::BorderSide.from_s s
      self.border = CrossDoc::Border.new top: side, right: side, left: side, bottom: side
    end

    def border_top(s)
      side = CrossDoc::BorderSide.from_s s
      self.border = CrossDoc::Border.new unless self.border
      self.border.top = side
    end

    def border_bottom(s)
      side = CrossDoc::BorderSide.from_s s
      self.border = CrossDoc::Border.new unless self.border
      self.border.bottom = side
    end

    def border_left(s)
      side = CrossDoc::BorderSide.from_s s
      self.border = CrossDoc::Border.new unless self.border
      self.border.left = side
    end

    def border_right(s)
      side = CrossDoc::BorderSide.from_s s
      self.border = CrossDoc::Border.new unless self.border
      self.border.right = side
    end

    def background_color(c)
      unless self.background
        self.background = CrossDoc::Background.new
      end
      self.background.color = c
    end

    def image_src(src)
      @raw[:src] = src
      hash = src.hash.to_s
      @raw[:hash] = hash
      @doc_builder.add_image src, hash
    end

    def node(tag, raw={})
      raw[:tag] = tag.upcase
      node_builder = NodeBuilder.new @doc_builder, raw
      yield node_builder
      @child_builders << node_builder
    end

    def horizontal_div(raw={})
      raw[:tag] = 'DIV'
      raw[:block_orientation] = 'horizontal'
      node_builder = NodeBuilder.new @doc_builder, raw
      yield node_builder
      @child_builders << node_builder
    end

    def div(raw={})
      raw[:tag] = 'DIV'
      raw[:block_orientation] = 'vertical'
      node_builder = NodeBuilder.new @doc_builder, raw
      yield node_builder
      @child_builders << node_builder
    end

    def child_width
      self.box.width - self.padding.left - self.padding.right
    end

    def flow_children
      if @block_orientation == :horizontal
        flow_children_horizontal
      else # vertical
        flow_children_vertical
      end
    end

    # flow_children, with extra logic for being a header or footer
    def flow_header_footer
      flow_children
      self.box.height = @min_height
    end

    # sets the position and size of the node based on the starting position and width (including margin)
    # returns the height consumed
    def flow(x, y, w)
      self.box.x = x + @margin.left
      self.box.y = y + @margin.top
      self.box.width = w - @margin.left - @margin.right

      # layout the children
      flow_children

      # compute/update the height
      if self.text && self.font
        # stupid simple font metrics
        # num_lines = (self.text.length * self.font.size * 0.48 / child_width).ceil
        num_lines = FontMetrics.num_lines self.text, child_width, self.font.size
        push_min_height (self.font.line_height || self.font.size) * num_lines
      end
      self.box.height = @min_height + self.padding.top + self.padding.bottom

      self.box.height + @margin.top + @margin.bottom
    end

    def editor_js(content, style={})
      EditorJsBuilder.new(self, style).build content
    end

    def markdown(content, style={})
      MarkdownBuilder.new(self, style).build content
    end

    def to_node
      @raw[:children] = @child_builders.map { |b| b.to_node }
      CrossDoc::Node.new @raw
    end

    private

    def total_child_weight
      @child_builders.map { |b| b.weight }.sum
    end

    def flow_children_vertical
      width = child_width
      x = self.padding.left
      y_top = self.padding.top
      y = y_top
      @child_builders.each do |b|
        dy = b.flow x, y, width
        y += dy
      end
      if (y-y_top) > self.box.height
        push_min_height y-y_top
      end
    end

    def flow_children_horizontal
      total_weight = total_child_weight
      width = child_width
      x = self.padding.left
      y = self.padding.top
      @child_builders.each do |b|
        w = (b.weight/total_weight.to_f*width).round.to_i
        dy = b.flow x, y, w
        x += w
        push_min_height dy
      end
    end

  end


  # DSL for creating a page in a document
  class PageBuilder < NodeBuilder
    include CrossDoc::RawShadow

    def initialize(doc_builder, raw)
      super
      @padding = Margin.new
      @box = doc_builder.page_box
    end

    attr_accessor :padding, :box

    def child_width
      @doc_builder.page_content_width
    end

    def to_page
      flow_children_vertical
      @raw[:children] = @child_builders.map { |b| b.to_node }
      CrossDoc::Page.new @raw
    end

  end


  # Creates a document through a ruby DSL
  class Builder

    attr_accessor :page_width, :page_height, :page_margin, :page_orientation

    def initialize(options={})
      @options = {
          page_size: 'us-letter',
          page_orientation: 'portrait',
          page_margin: '0.75in'
      }.merge options
      dimensions = Document.get_dimensions @options[:page_size], @options[:page_orientation]
      @page_width = dimensions[:width]
      @page_height = dimensions[:height]

      @page_margin = Margin.new
      margin_size = Document.page_margin_size @options[:page_margin]
      @page_margin.set_all margin_size

      @page_builders = []
      @images = {}
      @header_builder = nil
      @footer_builder = nil
    end

    def page_content_width
      @page_width - @page_margin.left - @page_margin.right
    end

    # a box at 0, 0 with page_width and page_height
    def page_box
      Box.new x: 0, y: 0, width: @page_width, height: @page_height
    end

    def page(raw={})
      page_builder = PageBuilder.new self, raw
      yield page_builder
      @page_builders << page_builder
    end

    def header(raw={})
      raw[:block_orientation] = :horizontal
      @header_builder = NodeBuilder.new self, raw
      yield @header_builder
      @header_builder.box.width = @page_width - @page_margin.left - @page_margin.right
      @header_builder.flow_header_footer
    end

    def footer(raw={})
      raw[:block_orientation] = :horizontal
      @footer_builder = NodeBuilder.new self, raw
      yield @footer_builder
      @footer_builder.box.width = @page_width - @page_margin.left - @page_margin.right
      @footer_builder.flow_header_footer
    end

    def add_image(src, hash)
      image_ref = CrossDoc::ImageRef.new src: src, hash: hash
      @images[hash] = image_ref
      image_ref
    end

    # clears the pages, header, and footer so the builder can be reused
    def clear_content
      @page_builders = []
      @header_builder = nil
      @footer_builder = nil
    end

    def to_doc
      attrs = {
          page_width: @page_width,
          page_height: @page_height,
          page_margin: @page_margin,
          pages:@page_builders.map {|pb| pb.to_page},
          images: @images
      }
      if @header_builder
        attrs[:header] = @header_builder.to_node
      end
      if @footer_builder
        attrs[:footer] = @footer_builder.to_node
      end
      CrossDoc::Document.new attrs
    end

  end

end
