require 'prawn'
require 'prawn-svg'

module CrossDoc

  # contains the pdf instance and current tree parent
  # as well as some helper methods for rendering
  class RenderContext

    def initialize(pdf, page)
      @pdf = pdf
      @page = page
      @parent = page
      @ancestors = [page]
    end

    attr_reader :pdf, :page, :parent

    def push_parent(new_parent)
      @parent = new_parent
      @ancestors.push new_parent
    end

    def pop_parent
      @ancestors.pop
      @parent = @ancestors.last
    end

    def render_node_background(node)
      bg = node.background
      return unless bg
      if bg.image
        # render the background image
      elsif bg.color
        @pdf.fill_color bg.color_no_hash
        @pdf.fill_rectangle [0.0, node.box.height], node.box.width, node.box.height
      end
    end

    def render_node_border(node)
      border = node.border
      if border
        if border.is_equal?
          @pdf.stroke_color border.top.color_no_hash
          @pdf.stroke_bounds
        else
          if border.top
            @pdf.stroke_color border.top.color_no_hash
            @pdf.stroke_horizontal_line 0.0, node.box.width, at: node.box.height
          end
          if border.bottom
            @pdf.stroke_color border.bottom.color_no_hash
            @pdf.stroke_horizontal_line 0.0, node.box.width, at: 0.0
          end
          if border.left
            @pdf.stroke_color border.left.color_no_hash
            @pdf.stroke_vertical_line 0.0, node.box.y, at: 0.0
          end
          if border.right
            @pdf.stroke_color border.right.color_no_hash
            @pdf.stroke_vertical_line 0.0, node.box.y, at: node.box.width
          end
        end
      elsif @show_overlays
        @pdf.stroke_color 'ff0000'
        @pdf.stroke_bounds
      end
    end

    def render_node_text(text, node)
      if node.font
        @pdf.font_size node.font.size
        color = node.font.color_no_hash
        style = node.font.weight
        align = node.font.align.to_sym
        leading = (node.font.line_height - node.font.size)*0.4
      else
        color = '000000'
        style = 'normal'
        align = :left
        leading = 0.0
      end
      pos = [node.padding.left,
             node.box.height - node.padding.top - leading*2.0]
      width = node.box.width - node.padding.left - node.padding.right
      height = node.box.height - node.padding.bottom - node.padding.bottom
      @pdf.bounding_box(pos, width: width, height: height) do
        @pdf.text text, color: color, align: align, leading: leading #, style: style
      end
    end

  end

  # renders a document to a PDF
  class Renderer

    def initialize(document)
      @doc = document
      @show_overlays = false
    end

    attr_reader :doc

    attr_accessor :show_overlays

    def download_images
      @doc.images.each do |h, image|
        image.download
      end
    end

    def dispose_images
      @doc.images.each do |h, image|
        image.dispose
      end
    end

    def to_pdf(path)
      download_images

      first_page = @doc.pages.first
      Prawn::Document.generate(path,
                               margin: first_page.padding.css_array) do |pdf|
        doc.pages.each do |page|
          ctx = RenderContext.new pdf, page
          unless page == first_page
            pdf.start_new_page margin: page.padding.css_array
          end
          if @show_overlays
            pdf.stroke_axis
          end
          page.children.each do |child|
            render_node ctx, child
          end
        end
      end

      dispose_images
    end

    private

    def render_node(ctx, node)
      pos = if ctx.parent.instance_of? Page
        [node.box.x - ctx.parent.padding.left,
               ctx.parent.height - node.box.y - ctx.parent.padding.top]
      else
        [node.box.x,
         ctx.parent.box.height - node.box.y]
      end

      ctx.pdf.bounding_box pos, width: node.box.width, height: node.box.height do
        ctx.render_node_background node

        all_text_children = true
        if node.children
          node.children.each do |child|
            if child.box
              all_text_children = false
            end
          end
        end
        if node.children && all_text_children
          text = node.children.map{|n| n.text}.join(' ')
          ctx.render_node_text text, node
        elsif node.text
          ctx.render_node_text node.text, node
        end

        # draw the border
        ctx.render_node_border node

        # render the image, if it is one
        if node.tag == 'IMG'
          if @doc.images.has_key? node.hash
            image = @doc.images[node.hash]
            if image.is_svg
              ctx.pdf.svg image.io, at: [0.0, node.box.height]
            else
              ctx.pdf.image image.io, fit: [node.box.width, node.box.height]
            end
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