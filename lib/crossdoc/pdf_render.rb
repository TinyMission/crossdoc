require 'prawn'
require 'prawn-svg'
require 'mini_magick'

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

      # Track list styles for rendering
      @list_style_stack = []
      @list_count_stack = []
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

    def leading_factor(family) = @pdf.font_families.dig(family, :leading_factor) || DEFAULT_LEADING_FACTOR

    def push_list_style(node)
      return unless node.list_style.present?

      @list_style_stack.push node.list_style
      @list_count_stack.push((node.start || 1) - 1)
    end

    def pop_list_style(node)
      return unless node.list_style.present?

      @list_style_stack.pop
      @list_count_stack.pop
    end

    def render_node_decorations(node)
      # list item
      if node.tag&.downcase == 'li' && !@list_style_stack.empty?
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

        list_style = @list_style_stack.last

        case list_style
        when 'disc', 'circle' # Circle
          radius = font.size / 5.0
          pos = [-4 * radius, node.box.height - (font.line_height / 2.0)]
          if list_style == 'disc'
            @pdf.fill_color(font.color_no_hash)
            @pdf.fill_circle(pos, radius)
          else
            @pdf.stroke_color(font.color_no_hash)
            @pdf.stroke_circle(pos, radius)
          end
        when 'square' # Square
          side_length = font.size / 2.5
          pos = [-2 * side_length, node.box.height - (font.line_height - side_length) / 2.0]
          @pdf.fill_color font.color_no_hash
          @pdf.fill_rectangle(pos, side_length, side_length)
        when 'decimal', 'lower_roman', 'upper_roman', 'lower_alpha', 'upper_alpha'
          # Text
          @list_count_stack[-1] += 1
          s = font.size
          @pdf.font_size s
          color = font.color_no_hash
          leading = (font.line_height - s)*leading_factor(font.family)
          pos = [-2.5 * s, node.box.height - leading]
          @pdf.bounding_box(pos, width: 2*s) do
            @pdf.text "#{list_style_text(list_style, @list_count_stack.last)}.", color: color, align: :right, leading: leading
          end
        else
          puts "!! don't know how to render list style '#{list_style}'"
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
        # CSS font families separated by commas
        families = node.font.family.split(',').map(&:strip)
        character_spacing = node.font.letter_spacing || 0

        true_family = families.find(&@pdf.font_families)
        if true_family.present? && @pdf.font_families[true_family].key?(style)
          @pdf.font(true_family, style:)
          @pdf.font_size node.font.size
        else
          @pdf.font('Helvetica', style:)
          @pdf.font_size node.font.size
        end
        leading = (node.font.line_height - node.font.size).to_f*leading_factor(true_family)
      else
        @pdf.font('Helvetica', style: :normal)
        @pdf.font_size 12
        character_spacing = 0
        color = '000000'
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
      @pdf.text_box(
        text,
        at: pos,
        width:,
        color:,
        align:,
        leading:,
        inline_format: true,
        final_gap: false,
        character_spacing:,
        overflow: :expand
      )
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

    private

    # Format an ordered list number using the given style.
    def list_style_text(list_style, list_count)
      case list_style
      when 'decimal' then list_count.to_s
      when 'lower_alpha' then list_count_render_alpha(list_count)
      when 'upper_alpha' then list_count_render_alpha(list_count).upcase
      when 'lower_roman' then list_count_render_roman(list_count)
      when 'upper_roman' then list_count_render_roman(list_count).upcase
      end
    end

    # Render an alphabetical list count. For lists of more than 26 items, a
    # second "digit" is used.
    def list_count_render_alpha(list_count)
      alpha_string = ''
      while list_count.positive?
        list_count, alpha_pos = list_count.divmod 26
        alpha_string << ('a'.ord + alpha_pos).chr
      end
      alpha_string
    end

    MOD_TO_ROMAN = {
      1000 => 'M',
      900 => 'CM',
      500 => 'D',
      400 => 'CD',
      100 => 'C',
      90 => 'XC',
      40 => 'XL',
      10 => 'X',
      9 => 'IX',
      5 => 'V',
      4 => 'IV',
      1 => 'I'
    }.freeze

    # Convert a list count to roman numerals.
    def list_count_render_roman(list_count)
      MOD_TO_ROMAN.reduce '' do |roman_string, (mod, roman)|
        whole_part, list_count = list_count.divmod mod
        roman_string << roman * whole_part
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
        image.download(skip_resize: @doc.images.count < 6)
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

    # Concatenate inline elements to use Prawn's inline formatting, converting:
    # - Linebreak tags into <br>
    # - Italicizing tags into <em>
    # - Bolding tags into <strong>
    def compute_compound_text(node)
      node.children.map do |child|
        text = child.text || compute_compound_text(child) || ''
        case child.tag
        when 'BR' then '<br>'
        when 'EM', 'I', 'Q' then "<i>#{text}</i>"
        when 'STRONG', 'B' then "<b>#{text}</b>"
        when 'DEL' then "<strikethrough>#{text}</strikethrough>"
        when 'U' then "<u>#{text}</u>"
        when 'SUP' then "<sup>#{text}</sup>"
        when 'SUB' then "<sub>#{text}</sub>"
        else text
        end
      end.join(' ')
    end

    # convert EditorJS-specific formatting tags to something compatible with Prawn.
    def preprocess_editorjs_tags(text)
      text
        .gsub(%r{<del[ '"A-Za-z1-9%-]*>([^<]*)</del>}, '<strikethrough>\1</strikethrough>')
        .gsub(%r{<code[ '"A-Za-z1-9%-]*>([^<]*)</code>}, '<font family="Courier">\1</font>')
    end

    # look at the children and try to compute a single font
    def compute_compound_font(node)
      return if node.font
      font = node.children.map(&:font).compact.first
      if font.present?
        node.font = CrossDoc::Font.default(
          color: font.color,
          size: font.size,
          family: font.family,
          line_height: font.line_height,
          letter_spacing: font.letter_spacing,
          align: font.align,
          style: 'normal',
          transform: font.transform
        )
      end
    end

    def render_node(ctx, node)
      # don't render nodes with no size
      if node.box.width == 0 || node.box.height == 0
        return
      end

      height = node.box.height
      pos = [node.box.x, ctx.parent.box.height - node.box.y]
      if node.tag == 'LI'
        font = node.font || node.children.lazy.map(&:font).compact.first || CrossDoc::Font.default
        list_level = node.list_level || 0
        pos[0] += font.size * list_level
      end

      ctx.pdf.bounding_box pos, width: node.box.width, height: height do
        ctx.render_node_background node

        if !node.children.empty? && node.children&.all? { _1.box.nil? } # All children are text
          text = preprocess_editorjs_tags(compute_compound_text(node))
          compute_compound_font node
          ctx.render_node_text(text, node)
        elsif node.input_value.present?
          text = preprocess_editorjs_tags node.input_value
          ctx.render_node_text(text, node)
        elsif node.text
          text = preprocess_editorjs_tags node.text
          ctx.render_node_text(text, node)
        end

        # draw the decorations

        ctx.push_list_style node
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

        ctx.pop_list_style node
      end


    end

  end

end
