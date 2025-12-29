# frozen_string_literal: true

require 'crossdoc/geom'
require 'minitest/autorun'

class TestBackground < Minitest::Test
  def test_from_json
    background = CrossDoc::Background.new({
                                            attachment: 'scroll',
                                            color: '#AA0000',
                                            image: 'https://placehold.co/600x400/EEE/31343C',
                                            position: 'top',
                                            repeat: 'space'
                                          })

    assert_equal('scroll', background.attachment, "Testing attachment")
    assert_equal('#AA0000', background.color, "Testing background")
    assert_equal('https://placehold.co/600x400/EEE/31343C', background.image, "Testing image")
    assert_equal('top', background.position, "Testing position")
    assert_equal('space', background.repeat, "Testing repeat")
  end

  def test_color_no_hash_on_hash_code
    background = CrossDoc::Background.new
    background.color = '#2F20A0'
    assert_equal('2F20A0', background.color_no_hash)
  end
end
