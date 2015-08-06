require 'minitest/autorun'
require 'crossdoc'

class TestRender < MiniTest::Unit::TestCase
  def setup
  end

  def test_render
    doc = CrossDoc::Document.from_file 'test/data/doc.json'

    renderer = CrossDoc::Renderer.new doc
    # renderer.show_overlays = true
    renderer.to_pdf 'test/output/test.pdf'
  end

  def test_report
    doc = CrossDoc::Document.from_file 'test/data/report.json'

    renderer = CrossDoc::Renderer.new doc
    # renderer.show_overlays = true
    renderer.to_pdf 'test/output/report.pdf'
  end

end