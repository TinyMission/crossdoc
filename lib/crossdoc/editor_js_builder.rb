# frozen_string_literal: true

require_relative './styler'

module CrossDoc
  # Used by the Builder to include content from EditorJS
  class EditorJsBuilder
    def initialize(container, styles = {})
      @container = container
      @styler = Styler.new styles
    end

    def build(content)
      content['blocks']&.each do |block|
        render_block(@container, block)
      end
    end

    private

    def render_paragraph(parent, paragraph)
      return if paragraph['text'].empty?

      parent.node 'P' do |paragraph_node|
        @styler.style_node paragraph_node
        paragraph_node.text = paragraph['text']
      end
    end

    def render_quote(parent, quote)
      return if quote['text'].empty?

      parent.node 'BLOCKQUOTE' do |quote_node|
        @styler.style_node quote_node
        quote_node.text = quote['text']
      end
    end

    def render_header(parent, header)
      return if header['text'].empty?

      parent.node "H#{header['level']}" do |header_node|
        @styler.style_node header_node
        header_node.text = header['text']
      end
    end

    def render_list(parent, list)
      return if list['items'].empty?

      element = case list['style']
                when 'ordered' then 'OL'
                when 'unordered', 'checklist' then 'UL'
                else throw "Unknown list style '#{list['style']}'"
                end

      list_bullet_style = element == 'UL' ? 'disc' : list['meta']['counterType']

      parent.node element do |list_node|
        list_node.list_style = list_bullet_style
        @styler.style_node list_node
        render_nested_list(list_node, list['items'])
      end
    end

    def render_nested_list(parent, items, level = 0)
      items&.each do |item|
        parent.node 'LI' do |item_node|
          item_node.list_level = level
          @styler.style_node item_node
          item_node.text = item['content']
        end
        render_nested_list(parent, item['items'], level + 1) unless item['items'].blank?
      end
    end

    def render_image(parent, image)
      parent.node 'IMG' do |image_node|
        @styler.style_node image_node
        image_source = image['file']['url']
        image_node.image_src(image_source).dimensions => { width: image_width, height: image_height }
        image_height = (image_height.to_f / image_width * parent.box.width) if image_width > parent.box.width
        image_node.push_min_height image_height
      end
    end

    def render_table(parent, table)
      return if table['content'].empty?

      parent.node 'TABLE' do |table_node|
        @styler.style_node table_node

        # No headings, render 'bare' table
        unless table['withHeadings']
          table.content&.each { |row| render_table_row(table_node, row) }
          break
        end

        render_thead(table_node, table['content'])
        render_tbody(table_node, table['content'])
      end
    end

    def render_thead(table_node, content)
      table_node.node 'THEAD' do |header_node|
        @styler.style_node header_node
        header_node.node 'TR', block_orientation: 'horizontal' do |header_row_node|
          @styler.style_node header_row_node
          content[0]&.each do |header_item|
            header_row_node.node 'TH' do |header_item_node|
              @styler.style_node header_item_node
              header_item_node.text = header_item
            end
          end
        end
      end
    end

    def render_tbody(table_node, content)
      table_node.node 'TBODY' do |body_node|
        @styler.style_node body_node
        content.drop(1).each do |row|
          render_table_row(body_node, row)
        end
      end
    end

    def render_table_row(parent, row)
      parent.node 'TR', block_orientation: 'horizontal' do |row_node|
        @styler.style_node row_node
        row.each do |row_item|
          row_node.node 'TD' do |row_item_node|
            @styler.style_node row_item_node
            row_item_node.text = row_item
          end
        end
      end
    end

    def render_block(parent, block)
      data = block['data']
      return if data.blank?

      case block['type']
      when 'paragraph' then render_paragraph(parent, data)
      when 'quote' then render_quote(parent, data)
      when 'header' then render_header(parent, data)
      when 'list' then render_list(parent, data)
      when 'image' then render_image(parent, data)
      when 'table' then render_table(parent, data)
      else raise "Cannot render: #{block.to_s.upcase}"
      end
    end
  end
end
