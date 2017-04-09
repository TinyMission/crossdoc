require 'crossdoc'
require_relative 'test_base'

class TestBuilder < TestBase
  def setup
  end

  def test_builder
    doc = build_demo_doc

    write_doc doc, 'builder', {paginate: 3}
  end

  def build_demo_doc
    builder = CrossDoc::Builder.new page_size: 'us-letter', page_orientation: 'portrait', page_margin: '0.5in'

    header_color = '#006688ff'
    body_color = '#222222ff'

    # header
    builder.header do |header|
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

    # footer
    footer_font = CrossDoc::Font.default size: 9, color: '666666', align: 'center'
    footer_padding = CrossDoc::Margin.new.set_all 12
    builder.footer do |footer|
      footer.div padding: footer_padding do |column|
        column.node 'p', font: footer_font do |p|
          p.text = 'This is the document footer'
        end
        column.node 'p', font: footer_font do |p|
          p.text = 'Page {{page_number}} of {{num_pages}}'
        end
      end
      footer.div padding: footer_padding do |column|
        column.node 'p', font: footer_font do |p|
          p.text = 'It will sit at the bottom of every page'
        end
      end
      footer.div padding: footer_padding do |column|
        column.node 'p', font: footer_font do |p|
          p.text = 'It usually contains boring but necessary information'
        end
      end
    end

    builder.page do |page|

      page.horizontal_div do |content|
        content.margin.top = 0
        content.node 'div', {weight: 2} do |left_content|
          left_content.node 'p', {} do |p1|
            p1.border_bottom '0.2px dashed #008888'
            p1.default_font size: 12, color: body_color
            p1.padding.set_all 8
            p1.text = 'Lorem ipsum dolor sit amet, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
          end
          left_content.node 'p', {} do |p2|
            p2.border_bottom '0.2px dotted #008888'
            p2.default_font size: 12, color: body_color
            p2.padding.set_all 8
            p2.text = 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.'
          end
          left_content.node 'p', {} do |p3|
            p3.border_bottom '0.2px solid #008888'
            p3.default_font size: 12, color: body_color
            p3.padding.set_all 8
            p3.text = 'Lorem ipsum dolor sit amet, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'
          end
        end
        content.node 'div', {weight: 1} do |right_content|
          right_content.div do |bordered_content|
            bordered_content.border_all '0.2px solid #aaaaaaff'
            bordered_content.padding.set_all 8
            bordered_content.margin.set_all 8
            bordered_content.default_font size: 14, color: body_color
            bordered_content.text = 'This content should have a border around it'
          end
          right_content.div do |bordered_content|
            bordered_content.border_all '0.2px solid #aaaaaaff'
            bordered_content.padding.set_all 8
            bordered_content.margin.set_all 8
            bordered_content.default_font size: 14, color: body_color
            bordered_content.text = 'Verylong textthat messeswith thewrapping'
          end
        end
      end

      th_font = CrossDoc::Font.default size: 12, color: '#ffffffff'
      td_font = CrossDoc::Font.default size: 12, color: '222222'
      cell_padding = CrossDoc::Margin.new.set_all 4
      page.node 'table', {} do |table|
        table.margin.top = 20
        table.margin.bottom = 20
        table.border_all '0.2px solid #aaaaaa'
        table.node 'tr', {block_orientation: :horizontal} do |header_row|
          header_row.background_color header_color
          header_row.node 'th', {weight: 3, font: th_font, padding: cell_padding} do |th|
            th.text = 'Description'
          end
          header_row.node 'th', {weight: 1, font: th_font, padding: cell_padding} do |th|
            th.text = 'Subtotal'
          end
          header_row.node 'th', {weight: 1, font: th_font, padding: cell_padding} do |th|
            th.text = 'Total'
          end
        end
        12.times do
          table.node 'tr', block_orientation: 'horizontal' do |tr|
            subtotal = 10.0 + rand*100.0
            tr.node 'td', weight: 3, font: td_font, padding: cell_padding do |td|
              td.text = "$#{'%.2f' % subtotal}"
            end
            tr.node 'td', weight: 1, font: td_font, padding: cell_padding do |td|
              td.text = "$#{'%.2f' % (subtotal*0.07)}"
            end
            tr.node 'td', weight: 1, font: td_font, padding: cell_padding do |td|
              td.text = "$#{'%.2f' % (subtotal*1.07)}"
            end
          end
        end
      end

      page.node 'p', {} do |p|
        p.default_font size: 12, color: body_color
        p.padding.set_all 8
        p.text = 'Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.'
      end
    end

    builder.to_doc
  end


  def test_markdown_builder
    doc = build_markdown_doc

    write_doc doc, 'markdown'
  end

  def build_markdown_doc
    builder = CrossDoc::Builder.new page_size: 'us-letter', page_orientation: 'portrait', page_margin: '0.5in'

    builder.to_doc
  end

end