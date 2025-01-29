require 'kramdown'
require_relative './styler'

module CrossDoc

  # Used by Builder to build content from a markdown source
  class MarkdownBuilder

    def initialize(container, styles={})
      @container = container
      @styler = Styler.new styles

    end

    def build(content)
      doc = Kramdown::Document.new content
      @converter = Kramdown::Converter::Html.method(:new).call(doc.root, Kramdown::Options.defaults)
      render_element @container, doc.root
    end


    private

    # combines the text of all child elements into one string
    def combine_text(children)
      children.map do |child|
        @converter.convert child
      end.join('')
    end

    def render_header(parent, elem)
      parent.node "H#{elem.options[:level]}" do |header|
        @styler.style_node header
        header.text = combine_text elem.children
      end
    end

    def render_image(parent, elem)
      parent.node 'IMG' do |img|
        src = elem.attr['src']
        image_ref = img.image_src src
        dims = image_ref.dimensions
        height = if dims[:width] > parent.box.width
                   dims[:height].to_f / dims[:width] * parent.box.width
                 else
                   dims[:height]
                 end.ceil
        img.push_min_height height
      end
    end

    def render_paragraph(parent, elem)
      children = elem.children
      return if elem.children.empty?
      if children.first.type == :img
        render_image parent, children.shift
      elsif children.last.type == :img
        render_image parent, children.pop
      end
      parent.node 'P' do |p|
        @styler.style_node p
        p.text = combine_text children
      end
    end

    def render_list(parent, elem)
      list_type = elem.type.to_s.upcase
      parent.node list_type do |list|
        if list_type == 'OL'
          list.list_style = 'decimal'
        elsif list_type == 'UL'
          list.list_style = 'disc'
        end
        @styler.style_node list
        elem.children.each do |child_elem|
          unless child_elem.type == :li
            raise "Lists must only contain li elements, not #{child_elem.type}"
          end
          list.node 'LI' do |item|
            @styler.style_node item
            item.text = combine_text(child_elem.children.first.children) # kramdown nests item content in a paragraph
          end
        end
      end
    end

    def render_element(node, elem)
      type = elem.type
      return if type == :blank
      case type
        when :root # container
          elem.children.each do |child_elem|
            render_element node, child_elem
          end
        when :header
          render_header node, elem
        when :p
          render_paragraph node, elem
        when :ul, :ol
          render_list node, elem
        else
          raise "Don't know how to render markdown element #{type}"
      end
    end

  end
end
