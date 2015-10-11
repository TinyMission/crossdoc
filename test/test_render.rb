require 'minitest/autorun'
require 'crossdoc'

class TestRender < MiniTest::Unit::TestCase
  def setup
  end

  def test_render_pdf
    doc = CrossDoc::Document.from_file 'test/data/doc.json'

    renderer = CrossDoc::PdfRenderer.new doc
    # renderer.show_overlays = true
    renderer.to_pdf 'test/output/test.pdf'
  end

end