require 'kramdown'

module CrossDoc

  # Used by Builder to build content from a markdown source
  class MarkdownBuilder

    DEFAULT_STYLE = {
        H1: {
           font: {
               size: 24
           },
           margin: {bottom: 6}
        },
        H2: {
           font: {
               size: 20
           },
           margin: {bottom: 6}
        },
        H3: {
           font: {
               size: 18
           },
           margin: {bottom: 6}
        },
        P: {
           font: {
               size: 12
           },
           margin: {bottom: 12}
        },
        UL: {
           margin: {bottom: 12, left: 20}
        },
        OL: {
           margin: {bottom: 12, left: 20}
        },
        LI: {
           font: {
               size: 12,
               line_height: 24
           }
        }
    }

    def initialize(container, style={})
      @container = container
      @style = DEFAULT_STYLE.deep_merge style
    end

    def build(content)
      doc = Kramdown::Document.new content
      render_element @container, doc.root
    end


    private

    def style_node(node)
      node_style = @style[node.tag.to_sym] || {}
      node.default_font node_style[:font] || {}

      unless node_style.has_key? :margin_cache
        raw_margin = {top: 0, right: 0, bottom: 0, left: 0}.merge (node_style[:margin] || {})
        node_style[:margin_cache] = Margin.new raw_margin
      end
      node.margin = node_style[:margin_cache]

      unless node_style.has_key? :padding_cache
        raw_padding = {top: 0, right: 0, bottom: 0, left: 0}.merge (node_style[:padding] || {})
        node_style[:padding_cache] = Margin.new raw_padding
      end
      node.padding = node_style[:padding_cache]
    end

    # combines the text of all child elements into one string
    def combine_text(children)
      children.map do |child|
        case child.type
          when :em
            "<em>#{child.children.first.value}</em>"
          when :strong
            "<strong>#{child.children.first.value}</strong>"
          else
            child.value
        end
      end.join('')
    end

    def render_header(parent, elem)
      parent.node "H#{elem.options[:level]}" do |header|
        style_node header
        header.text = combine_text elem.children
      end
    end

    def render_paragraph(parent, elem)
      parent.node 'P' do |p|
        style_node p
        p.text = combine_text elem.children
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
        style_node list
        elem.children.each do |child_elem|
          unless child_elem.type == :li
            raise "Lists must only contain li elements, not #{child_elem.type}"
          end
          list.node 'LI' do |item|
            style_node item
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
