require 'crossdoc/styler'
require 'crossdoc/builder'
require 'minitest/autorun'

class TestStyler < Minitest::Test
  def setup
    # Test styler with default styles.
    @default_styler = CrossDoc::Styler.new({})
  end

  def test_header_tags
    tag_cases = [
      { tag: 'h1', font_size: 32 },
      { tag: 'h2', font_size: 26 },
      { tag: 'h3', font_size: 20 },
    ]

    tag_cases.each do |tag_case|
      node = new_styled_tag_node tag_case[:tag]
      assert_in_delta(tag_case[:font_size], node.font.size.to_f, 0.01, "Testing font size for #{tag_case[:tag]}")
      assert_in_delta(8, node.margin.bottom.to_f, 0.01, "Testing bottom margin for #{tag_case[:tag]}")
    end
  end

  def test_table_tag
    node = new_styled_tag_node 'table'
    each_node_border node do |side|
      assert_in_delta(1, side.width.to_f, 0.01, "Testing border width for #{side}")
      assert_equal('solid', side.style, "Testing border style for #{side}")
      assert_equal('#000000', side.color, "Testing border color for #{side}")
    end
  end

  def test_th_tag
    node = new_styled_tag_node 'th'
    assert_in_delta(13, node.font.size.to_f, 0.01, "Testing font size")
    assert_equal('center', node.font.align, "Testing font alignment")
  end

  def test_thead_tag
    node = new_styled_tag_node 'thead'
    assert_in_delta(0.2, node.border.bottom.width.to_f, 0.01, "Testing bottom border width")
  end

  def test_tr_tag
    node = new_styled_tag_node 'tr'
    assert_in_delta(0.2, node.border.bottom.width.to_f, 0.01, "Testing bottom border width")
  end

  def test_td_tag
  node = new_styled_tag_node 'td'

    assert_in_delta(9, node.font.size.to_f, 0.01, "Testing font size")
    assert_equal('center', node.font.align, "Testing font alignment")

    assert_in_delta(1, node.margin.bottom.to_f, 0.01, "Testing bottom margin")
    assert_in_delta(1, node.margin.top.to_f, 0.01, "Testing top margin")
    assert_in_delta(8, node.margin.left.to_f, 0.01, "Testing left margin")
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
