# frozen_string_literal: true

require 'crossdoc/geom'
require 'minitest/autorun'

class MarginTest < Minitest::Test
  def test_from_json
    margin = CrossDoc::Margin.new({
                                    top: 10,
                                    left: 11,
                                    right: 12,
                                    bottom: 13
                                  })

    assert_equal(10, margin.top, "Testing top")
    assert_equal(11, margin.left, "Testing left")
    assert_equal(12, margin.right, "Testing right")
    assert_equal(13, margin.bottom, "Testing bottom")
  end
end
