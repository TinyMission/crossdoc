require 'prawn'
require 'prawn-svg'

module CrossDoc

  # contains the pdf instance and current tree parent
  # as well as some helper methods for rendering
  class PdfRenderContext

    def initialize(pdf, doc, page)
      @pdf = pdf
      @doc = doc
      @page = page
      @page_number = @doc.pages.index(@page) + 1
      @parent = page
      @ancestors = [page]
      @show_overlays = false
      @guide_color = '00ffff'
      @list_style = nil
      @list_count = 0
    end

    attr_reader :pdf, :doc, :page, :parent

    attr_accessor :show_overlays, :guide_color

    def push_parent(new_parent)
      @parent = new_parent
      @ancestors.push new_parent
    end

    def pop_parent
      @ancestors.pop
      @parent = @ancestors.last
    end

    def process_text_meta(t)
      if t.index '{{'
        t = t.gsub('{{page_number}}', @page_number.to_s)
            .gsub('{{num_pages}}', @doc.pages.count.to_s)
      end
      t
    end

    def render_node_background(node)
      bg = node.background
      return unless bg
      if bg.image
        # TODO: render the background image
      elsif bg.color
        @pdf.fill_color bg.color_no_hash
        @pdf.fill_rectangle [0.0, node.box.height], node.box.width, node.box.height
      end
    end

    # initializes the canvas to draw based on the given border side (width, color, and style)
    def init_border_side(side)
      @pdf.line_width = side.width
      @pdf.stroke_color side.color_no_hash
      if side.style == 'dashed'
        @pdf.dash 9
      elsif side.style == 'dotted'
        @pdf.dash 2
      else
        @pdf.undash
      end
    end

    def render_node_border(node)
      border = node.border
      if border
        if border.is_equal?
          init_border_side border.top
          @pdf.stroke_bounds
        else
          if border.top
            init_border_side border.top
            @pdf.stroke_horizontal_line 0.0, node.box.width, at: node.box.height
          end
          if border.bottom
            init_border_side border.bottom
            @pdf.stroke_horizontal_line 0.0, node.box.width, at: 0.0
          end
          if border.left
            init_border_side border.left
            @pdf.stroke_vertical_line 0.0, node.box.y, at: 0.0
          end
          if border.right
            init_border_side border.right
            @pdf.stroke_vertical_line 0.0, node.box.y, at: node.box.width
          end
        end
        @pdf.undash
      elsif @show_overlays
        @pdf.line_width = 0.2
        @pdf.stroke_color 'ff0000'
        @pdf.undash
        @pdf.stroke_bounds
      end
    end

    DEFAULT_LEADING_FACTOR = 0.4

    def leading_factor(family)
      if @pdf.font_families[family]
        @pdf.font_families[family][:leading_factor] || DEFAULT_LEADING_FACTOR
      else
        DEFAULT_LEADING_FACTOR
      end
    end

    # these list styles will be rendered so they should be preferentially parsed
    RENDERED_LIST_STYLES = %w[disc decimal]

    def render_node_decorations(node)
      # keep track of the list style so that we can render item decorations when they come around
      # list styles will often look like: "outside+none+disc"
      if node.list_style
        @list_style = nil
        RENDERED_LIST_STYLES.each do |style|
          if node.list_style.index(style)
            @list_style = style
            break
          end
        end
        @list_count = 0
      end

      # list item
      if node.tag&.downcase == 'li' && @list_style
        font = node.font
        unless font
          node.children.each do |child|
            if child.font
              font = child.font
              break
            end
          end
        end
        unless font
          font = CrossDoc::Font.default
        end
        case @list_style
          when 'disc'
            r = font.size/5.0
            pos = [-4*r, node.box.height - (font.line_height/2.0)]
            @pdf.fill_color = font.color_no_hash
            @pdf.circle pos, r
            @pdf.fill
          when 'decimal'
            @list_count += 1
            s = font.size
            @pdf.font_size s
            color = font.color_no_hash
            leading = (font.line_height - s)*leading_factor(font.family)
            pos = [-2.5*s, node.box.height - leading]
            @pdf.bounding_box(pos, width: 2*s) do
              @pdf.text "#{@list_count}.", color: color, align: :right, leading: leading
            end
          else
            puts "!! don't know how to render list style '#{@list_style}'"
        end
      end
    end

    def render_node_image(image, node)
      if image.is_svg
        STDOUT.flush
        if node.box.height > 0 && node.box.width > 0
          begin
            @pdf.svg image.io, at: [0.0, node.box.height], width: node.box.width, cache_images: true
          rescue Exception => ex
            puts "Error rendering SVG: #{ex.message}"
          end
        end
      else
        @pdf.image image.io, fit: [node.box.width, node.box.height]
      end
    end

    def render_node_text(text, node)
      if node.font
        color = node.font.color_no_hash
        style = node.font.prawn_style
        align = node.font.align.to_sym
        text = node.font.transform_text(text)
        family = node.font.family.strip
        character_spacing = node.font.letter_spacing || 0
        if family.length > 0 && @pdf.font_families[family] && @pdf.font_families[family][style]
          @pdf.font family
          @pdf.font_size node.font.size
        else
          @pdf.font 'Helvetica'
          @pdf.font_size node.font.size
        end
        leading = (node.font.line_height - node.font.size).to_f*leading_factor(family)
      else
        @pdf.font 'Helvetica'
        @pdf.font_size 12
        character_spacing = 0
        color = '000000ff'
        style = :normal
        align = :left
        leading = 0.0
      end
      text = process_text_meta text

      # remove bad whitespace
      text = text.gsub /\s+/, ' '

      # add line breaks for BR tags
      text = text.gsub /<br>/, "\n"

      pos = if node.padding
              [node.padding.left, node.box.height - node.padding.top - leading]
            else
              [0, node.box.height - leading]
            end
      width = if node.padding
                node.box.width - node.padding.left - node.padding.right + 2 # +2 hack
              else
                node.box.width + 2
              end
      @pdf.fill_color color # need to reset the fill color every time when using text_box
      @pdf.text_box text, at: pos, width: width, color: color, align: align, leading: leading,
                      style: style, inline_format: true, final_gap: false,
                      character_spacing: character_spacing, overflow: :expand
    end

    def render_horizontal_guides(ys)
      @pdf.line_width = 0.2
      @pdf.stroke_color @guide_color
      ys.each do |y|
        @pdf.stroke_horizontal_line 0, @doc.page_width, at: @doc.page_height - y
      end
    end

    def render_box_guides(boxes)
      @pdf.line_width = 0.2
      @pdf.stroke_color @guide_color
      boxes.each do |box|
        @pdf.stroke_rectangle [box.x, @doc.page_height-box.y], box.width, box.height
      end
    end

  end

  # renders a document to a PDF
  class PdfRenderer

    def initialize(document)
      @doc = document
      @show_overlays = false
      @horizontal_guides = []
      @box_guides = []
      @font_families = {}
    end

    attr_reader :doc

    attr_accessor :show_overlays

    # shows a horizontal line at the given distance from the top of the page
    def add_horizontal_guide(y)
      @horizontal_guides << y
    end

    # draws a box (must be a CrossDoc::Box object)
    def add_box_guide(box)
      unless box.instance_of? CrossDoc::Box
        raise 'Must pass a Geom::Box parameters'
      end
      @box_guides << box
    end

    def download_images
      @doc.images.each do |h, image|
        image.download @doc.images.count
      end
    end

    def dispose_images
      @doc.images.each do |h, image|
        image.dispose
      end
    end

    def register_font_family(name, styles)
      @font_families[name] = styles
    end

    def to_pdf(path)
      download_images

      # compute header and footer height
      header_height = 0
      if @doc.header
        header_height = @doc.header.box.height
      end
      footer_height = 0
      if @doc.footer
        footer_height = @doc.footer.box.height
      end

      first_page = @doc.pages.first

      page_margin = [0, 0, 0, 0]
      page_layout = (@doc.page_orientation || 'portrait').to_sym
      Prawn::Document.generate(path, margin: page_margin, page_layout: page_layout) do |pdf|

        # register the fonts
        @font_families.each do |name, styles|
          pdf.font_families.update name => styles
        end

        @doc.pages.each do |page|
          ctx = PdfRenderContext.new pdf, doc, page
          ctx.show_overlays = @show_overlays
          unless page == first_page
            pdf.start_new_page margin: page_margin, layout: page_layout
          end
          if @show_overlays
            pdf.stroke_axis
          end

          # render header
          if header_height > 0
            ctx.pdf.bounding_box [@doc.page_margin.left, @doc.page_height-@doc.page_margin.top],
                                 width: @doc.header.box.width, height: @doc.header.box.height do
              header_parent = Node.new box: @doc.header.box
              ctx.push_parent header_parent
              render_node ctx, @doc.header
              ctx.pop_parent
            end
          end

          # compute footer height and render it
          if footer_height > 0
            ctx.pdf.bounding_box [@doc.page_margin.left, @doc.page_margin.bottom+footer_height],
                                 width: @doc.footer.box.width, height: @doc.footer.box.height do
              footer_parent = Node.new box: @doc.footer.box
              ctx.push_parent footer_parent
              render_node ctx, @doc.footer
              ctx.pop_parent
            end
          end

          # wrap the actual page rendering in a smaller box to account for the header and footer
          content_width = @doc.page_width-@doc.page_margin.left-@doc.page_margin.right
          content_height = @doc.page_height-@doc.page_margin.top-@doc.page_margin.bottom-header_height-footer_height
          ctx.pdf.bounding_box [@doc.page_margin.left, @doc.page_height-@doc.page_margin.top-header_height],
                               width: content_width,
                               height: content_height do
            content_parent = Node.new box: Box.new(x: 0, y: 0, width: content_height, height: content_height)
            ctx.push_parent content_parent
            page.children.each do |child|
              render_node ctx, child
            end
            ctx.pop_parent
          end
          ctx.render_horizontal_guides @horizontal_guides
          ctx.render_box_guides @box_guides
        end # page
      end # pdf

      dispose_images
    end

    private

    # concatenate all child text into a single string, taking into account line breaks
    def compute_compound_text(node)
      node.children.map do |n|
        if n.tag == 'BR'
          '<br>'
        elsif n.tag == 'EM'
          text = n.text || compute_compound_text(n) || ""
          "<em>#{text}</em>"
        elsif n.tag == 'STRONG'
          text = n.text || compute_compound_text(n) || ""
          "<strong>#{text}</strong>"
        else
          n.text
        end
      end.join(' ')
    end

    # look at the children and try to compute a single font
    def compute_compound_font(node)
      return if node.font
      fonts = node.children.map{|child| child.font}.compact
      if fonts.length > 0
        node.font = fonts.first
      end
    end

    def render_node(ctx, node)
      # don't render nodes with no size
      if node.box.width == 0 || node.box.height == 0
        return
      end

      height = node.box.height
      pos = [node.box.x, ctx.parent.box.height - node.box.y]

      ctx.pdf.bounding_box pos, width: node.box.width, height: height do
        ctx.render_node_background node

        all_text_children = true
        if node.children
          node.children.each do |child|
            if child.box
              all_text_children = false
            end
          end
        end
        if node.children && node.children.length > 0 && all_text_children
          text = compute_compound_text node
          compute_compound_font node
          ctx.render_node_text text, node
        elsif node.input_value && node.input_value.length > 0
          ctx.render_node_text node.input_value, node
        elsif node.text
          ctx.render_node_text node.text, node
        end

        # draw the decorations
        ctx.render_node_decorations node

        # draw the border
        ctx.render_node_border node

        # render the image, if it is one
        if node.tag == 'IMG'
          if @doc.images.has_key? node.hash
            image = @doc.images[node.hash]
            ctx.render_node_image image, node
          else
            puts "Document does not contain image #{node.hash}"
          end
        end

        if node.children
          ctx.push_parent node
          node.children.each do |child|
            if child.box
              render_node ctx, child
            end
          end
          ctx.pop_parent
        end

      end


    end

  end

end
