# frozen_string_literal: true

require 'crossdoc/geom'
require 'minitest/autorun'

class FontTest < Minitest::Test
  def test_from_json
    font = CrossDoc::Font.new({
                                color: '#00FFFF',
                                size: '12',
                                weight: 'bold',
                                decoration: 'underline',
                                family: 'Comic Sans',
                                style: 'italic',
                                line_height: '14',
                                letter_spacing: '14',
                                align: 'center',
                                transform: 'lowercase'
                              })

    assert_equal('#00FFFF', font.color, "Testing font color")
    assert_equal("12", font.size, "Testing font size")
    assert_equal('bold', font.weight, "Testing font weight")
    assert_equal('underline', font.decoration, "Testing font decoration")
    assert_equal('Comic Sans', font.family, "Testing font family")
    assert_equal('italic', font.style, "Testing font style")
    assert_equal("14", font.line_height, "Testing line height")
    assert_equal('center', font.align, "Testing font alignment")
    assert_equal('lowercase', font.transform, "Testing text transform")
  end

  def test_transform_text
    expected = {
      capitalize: 'Test text',
      uppercase: 'TEST TEXT',
      lowercase: 'test text',
      none: 'Test text',
    }.with_indifferent_access

    %w[capitalize uppercase lowercase none].each do |transform|
      font = CrossDoc::Font.new({ transform: })
      transformed = font.transform_text('Test text')
      assert_equal(expected[transform], transformed, "Testing #{transform}")
    end
  end

  def test_prawn_style
    cases = [
      # No style
      { weight: nil, style: nil, expected: :normal },
      # Italic only
      { weight: 'nil', style: 'italic', expected: :italic },
      # Bold only
      { weight: 'bold', style: nil, expected: :bold },
      # Bold and italic
      { weight: 'bold', style: 'italic', expected: :bold_italic},
      # Oblique
      { weight: 'nil', style: 'oblique', expected: :italic },
      # Numeric weight
      { weight: '0', style: nil, expected: :normal },
      { weight: '400', style: nil, expected: :normal },
      { weight: '700', style: nil, expected: :bold },
      { weight: '1000', style: nil, expected: :bold },
    ]

    cases.each do |test_case|
      test_case => { weight:, style:, expected: }
      font = CrossDoc::Font.new({ weight:, style: })
      assert_equal(expected, font.prawn_style, "Testing #{test_case}")
    end
  end

  def test_default_font
    font = CrossDoc::Font.default()
    assert_equal('helvetica,sans-serif', font.family, "Testing font family")
    assert_equal('#000000', font.color, "Testing font color")
    assert_in_delta(12, font.size.to_f, 0.01, "Testing font size")
    assert_equal('normal', font.weight, "Testing font weight")
    assert_equal(:left, font.align, "Testing font alignment")
    assert_in_delta(16, font.line_height.to_f, 0.01, "Testing font line height")
  end
end
