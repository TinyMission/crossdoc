# frozen_string_literal: true

require 'crossdoc/geom'
require 'minitest/autorun'

class TestBox < Minitest::Test
  def test_from_json
    x = Random.rand 10
    y = Random.rand 10
    width = Random.rand 10
    height = Random.rand 10

    box = CrossDoc::Box.new({ x:, y:, width:, height: }) 

    assert_equal(width, box.width, "Testing width")
    assert_equal(height, box.height, "Testing height")
    assert_equal(x, box.x, "Testing X")
    assert_equal(y, box.y, "Testing Y")
  end
end
