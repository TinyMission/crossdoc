require 'minitest/autorun'
require 'crossdoc'

class TestRender < Minitest::Test
  def setup
  end

  def render_pdf_named(name)
    doc = CrossDoc::Document.from_file "test/data/#{name}.json"

    File.open("test/output/#{name}.json", 'wt') do |f|
      f.write JSON.pretty_generate(doc.to_raw)
    end

    renderer = CrossDoc::PdfRenderer.new doc
    renderer.show_overlays = true
    renderer.add_horizontal_guide 3.5.inches
    renderer.add_box_guide CrossDoc::Box.new(x: 0.875.inches, y: 2.5.inches, width: 3.inches, height: 1.125.inches)
    renderer.to_pdf "test/output/#{name}.pdf"
  end


  def test_render_pdf
    render_pdf_named 'doc'
    render_pdf_named 'report'
  end

end