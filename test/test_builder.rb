require 'minitest/autorun'
require 'crossdoc'


class TestBuilder < Minitest::Test
  def setup
  end

  def test_builder
    doc = build_demo_doc

    File.open('test/output/builder.json', 'wt') do |f|
      f.write JSON.pretty_generate(doc.to_raw)
    end

    renderer = CrossDoc::PdfRenderer.new doc
    # renderer.show_overlays = true
    renderer.to_pdf 'test/output/builder.pdf'
  end

  def build_demo_doc
    builder = CrossDoc::Builder.new

    header_color = '#006688ff'
    body_color = '#222222ff'

    builder.page size: 'us-letter', orientation: 'portrait', page_margin: '0.5in' do |page|
      page.horizontal_div do |header|
        header.horizontal_div do |left_header|
          left_header.node 'img', {src: 'https://placeholdit.imgix.net/~text?txtsize=32&txt=Logo&w=100&h=80&fm=png'} do |logo|
            logo.push_min_height 100
            logo.margin.set_all 8
          end
          left_header.div do |company_info|
            info_font = CrossDoc::Font.default size: 8, color: body_color
            company_info.div do |name_row|
              name_row.font = info_font
              name_row.padding.set_all 4
              name_row.text = 'ACME LLC'
            end
            company_info.div do |phone_row|
              phone_row.font = info_font
              phone_row.padding.set_all 4
              phone_row.text = '952-555-1234'
            end
          end
        end
        header.div do |right_header|
          right_header.node 'h1' do |n|
            n.default_font size: 32, align: :right, color: header_color
            n.text = 'Hello World'
          end
          right_header.node 'h2' do |n|
            n.default_font size: 24, align: :right, color: header_color
            n.text = 'Subheader'
          end
        end
      end

      page.horizontal_div do |content|
        content.margin.top = 20
        content.node 'div', {weight: 2} do |left_content|
          left_content.node 'p', {} do |p1|
            p1.border_bottom '0.2px solid #008888'
            p1.default_font size: 12, color: body_color
            p1.padding.set_all 8
            p1.text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
          end
          left_content.node 'p', {} do |p2|
            p2.default_font size: 12, color: body_color
            p2.padding.set_all 8
            p2.text = 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.'
          end
        end
        content.node 'div', {weight: 1} do |right_content|
          right_content.div do |bordered_content|
            bordered_content.border_all '1px solid #aaaaaaff'
            bordered_content.padding.set_all 8
            bordered_content.margin.set_all 8
            bordered_content.default_font size: 14, color: body_color
            bordered_content.text = 'This content should have a border around it'
          end
        end
      end

      header_font = CrossDoc::Font.default size: 12, color: '#ffffffff'
      cell_padding = 4
      page.node 'table', {} do |table|
        table.margin.top = 20
        table.margin.bottom = 20
        table.node 'tr', {block_orientation: :horizontal} do |header_row|
          header_row.background_color header_color
          header_row.node 'th', {weight: 3} do |th|
            th.padding.set_all cell_padding
            th.font = header_font
            th.text = 'Description'
          end
          header_row.node 'th', {weight: 1} do |th|
            th.padding.set_all cell_padding
            th.font = header_font
            th.text = 'Subtotal'
          end
          header_row.node 'th', {weight: 1} do |th|
            th.padding.set_all cell_padding
            th.font = header_font
            th.text = 'Total'
          end
        end
      end
    end

    builder.to_doc
  end

end