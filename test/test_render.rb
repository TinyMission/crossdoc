require 'crossdoc/tree'
require_relative 'test_base'

class TestRender < TestBase
  def setup
  end

  def render_pdf_named(name, options={})
    doc = CrossDoc::Document.from_file "test/input/#{name}.json"

    File.open("test/output/#{name}.json", 'wt') do |f|
      f.write JSON.pretty_generate(doc.to_raw)
    end

    write_doc doc, name, options
  end


  def test_render_pdf
    render_pdf_named 'doc'
    render_pdf_named 'report', {paginate: 6}
  end

end
