require 'crossdoc/converter'
require_relative 'test_base'

class TestConvert < TestBase

  def test_convert

    CrossDoc::Converter.new([
      'test/input/markdown.md',
      '-o', 'test/output/convert.pdf',
      '-s', 'test/input/styles.yml',
      '--center-footer', '(c) 2017 Tiny Mission LLC.',
      '--right-footer', '{{page_number}} of {{num_pages}}',
      '-v'
    ])

  end

end
