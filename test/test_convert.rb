require 'crossdoc'
require_relative 'test_base'

class TestConvert < TestBase

  def test_convert

    CrossDoc::Converter.new(%w(
      test/input/markdown.md
      -o test/output/convert.pdf
      -v
    ))

  end

end