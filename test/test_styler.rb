require 'crossdoc'
require 'minitest/autorun'

class TestStyler < Minitest::Spec
  before do
    # Test styler with default styles.
    @default_styler = CrossDoc::Styler.new({})
  end

  describe 'when styling header tags' do
    it 'must render with the correct font size and margins' do
      tag_cases = [
        { tag: 'h1', font_size: 32 },
        { tag: 'h2', font_size: 26 },
        { tag: 'h3', font_size: 20 },
      ]

      tag_cases.each do |tag_case|
        node = new_styled_tag_node tag_case[:tag]
        _(node.font.size).must_be_close_to tag_case[:font_size]
        _(node.margin.bottom).must_be_close_to 8
      end
    end
  end

  describe 'when styling paragraph tags' do
    it 'must render with the correct font size and margins' do
      node = new_styled_tag_node 'p'
      _(node.font.size).must_be_close_to 12
      _(node.margin.bottom).must_be_close_to 12
    end
  end

  describe 'when styling tables' do
    it 'must give the table with the correct styles' do
      node = new_styled_tag_node 'table'
      each_node_border node do |side|
        _(side.width).must_be_close_to 1
        _(side.style).must_equal 'solid'
        _(side.color).must_equal '#000000'
      end
    end

    it 'must give header items with the correct styles' do
      node = new_styled_tag_node 'th'
      _(node.font.size).must_be_close_to 13
      _(node.font.align).must_equal 'center'
    end

    it 'must give headers the correct styles' do
      node = new_styled_tag_node 'thead'

      _(node.border.bottom.width).must_be_close_to 0.2
    end

    it 'must give rows the correct styling' do
      node = new_styled_tag_node 'tr'
      _(node.border.bottom.width).must_equal 0.2
    end
  end

  it 'must give table cells the correct styling' do
    node = new_styled_tag_node 'td'

    _(node.font.size).must_be_close_to 9
    _(node.font.align).must_equal 'center'

    _(node.margin.bottom).must_be_close_to 1
    _(node.margin.top).must_be_close_to 1
    _(node.margin.left).must_be_close_to 8
    _(node.margin.right).must_be_close_to 8
  end 

  private

  def new_styled_tag_node(tag)
    node = CrossDoc::NodeBuilder.new(nil, tag:)
    @default_styler.style_node node
    return node
  end

  def each_node_border(node, &block)
    border = node.border
    %i[top bottom left right].each do |direction|
      border_direction = border.send direction
      block.call border_direction
    end
  end
end
