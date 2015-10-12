require 'minitest/autorun'
require 'crossdoc'

class TestRender < Minitest::Test
  def setup
  end

  def test_render_pdf
    doc = CrossDoc::Document.from_file 'test/data/doc.json'

    File.open('test/output/test.json', 'wt') do |f|
      f.write JSON.pretty_generate(doc.to_raw)
    end

    renderer = CrossDoc::PdfRenderer.new doc
    renderer.show_overlays = true
    renderer.to_pdf 'test/output/test.pdf'
  end

end