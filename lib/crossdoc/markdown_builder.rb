# frozen_string_literal: true

require 'kramdown'
require_relative './styler'

module CrossDoc
  # Used by Builder to build content from a markdown source
  class MarkdownBuilder
    def initialize(container, styles = {}, image_mapper:)
      @container = container
      @styler = Styler.new styles
      @image_mapper = image_mapper
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
        image_ref = img.image_src @image_mapper.call(src)
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
            raise "Lists must only contain 'LI' elements, not #{child_elem.type.to_s.upcase}"
          end

          list.node 'LI' do |item|
            @styler.style_node item
            item.text = combine_text(child_elem.children.first.children) # kramdown nests item content in a paragraph
          end
        end
      end
    end

    def render_table(parent, elem)
      return if elem.children.empty?

      parent.node 'TABLE' do |table|
        @styler.style_node table

        # Check if 'bare' table (i.e. no thead, tbody, etc.)
        if elem.children[0].type == :tr
          elem.children.each do |row|
            render_table_row(table, row)
          end
          return
        end

        # Otherwise, 'full' table
        elem.children.each do |child|
          unless %i[thead tbody tfoot].include? child.type
            raise "Full tables must only contain 'TBODY', 'THEAD', and 'TFOOT' elements, not #{child.type.to_s.upcase}"
          end

          table.node child.type.to_s.upcase do |subtable|
            @styler.style_node subtable

            # Render the rows for each subtable
            child.children.each do |row|
              render_table_row(subtable, row)
            end
          end
        end
      end
    end

    def render_horizontal_rule(parent)
      parent.node 'P' do |f|
        @styler.style_node f
        f.border_bottom "1px solid #{defined?(@body_color) ? @body_color : '#222222'}"
      end
      parent.node 'P' do |f|
        @styler.style_node f
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
      when :hr
        render_horizontal_rule node
      when :table
        render_table node, elem
      else
        raise "Don't know how to render markdown element #{type.to_s.upcase}"
      end
    end

    def render_table_row(parent, elem)
      return if elem.children.empty?

      parent.node 'TR', block_orientation: 'horizontal' do |row|
        elem.children.each do |entry|
          unless %i[th td].include? entry.type
            raise "Table row must have only 'TH' or 'TD' child elements, not #{entry.type.to_s.upcase}"
          end

          row.node entry.type.to_s.upcase do |data_element|
            @styler.style_node data_element
            data_element.text = combine_text entry.children
          end
        end
      end
    end
  end
end
