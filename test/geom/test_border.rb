# frozen_string_literal: true

require 'crossdoc/geom'
require 'minitest/autorun'

class BorderTest < Minitest::Test
  def test_from_json
    border_params = {
      top: { width: 1, color: '#000000' },
      left: { width: 2, color: '#00FFFF', style: 'dashed' },
      right: { width: 3, color: '#FF00FF', style: 'dotted' },
      bottom: { width: 4, color: '#FFFF00', style: 'solid' }
    }

    border = CrossDoc::Border.new border_params

    assert_equal(CrossDoc::BorderSide.new(border_params[:top]), border.top, "Testing top border")
    assert_equal(CrossDoc::BorderSide.new(border_params[:left]), border.left, "Testing left border")
    assert_equal(CrossDoc::BorderSide.new(border_params[:right]), border.right, "Testing right border")
    assert_equal(CrossDoc::BorderSide.new(border_params[:bottom]), border.bottom, "Testing bottom border")
  end
end

class BorderSideTest < Minitest::Test
  def test_from_json
    border_side = CrossDoc::BorderSide.new({
                                             width: 100,
                                             color: '#FF00FF'
                                           })

    assert_equal(100, border_side.width, "Testing border width")
    assert_equal('#FF00FF', border_side.color, "Testing border color")
    assert_equal('solid', border_side.style, "Testing border style")
  end

  def test_from_s
    cases = {
      '1px solid' => CrossDoc::BorderSide.new({ width: 1, color: '#000000', style: 'solid' }),
      '2px' => CrossDoc::BorderSide.new({ width: 2, color: '#000000', style: 'solid' }),
      '100px dashed #FFFF00' => CrossDoc::BorderSide.new({ width: 100, color: '#FFFF00', style: 'dashed' })
    }

    cases.map do |input, expected_side|
      actual_side = CrossDoc::BorderSide.from_s input
      assert_equal(expected_side, actual_side, "Testing border string '#{input}'")
    end
  end
end
