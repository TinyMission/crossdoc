# frozen_string_literal: true

require 'crossdoc/builder'
require 'crossdoc/tree'
require 'minitest/autorun'

class DocBuilderTest < Minitest::Test
  def setup
    @doc_builder = CrossDoc::Builder.new
  end

  DEFAULT_PAGE_BOX = CrossDoc::Box.new(x: 0, y: 0, width: 612, height: 792) # Portrait letter paper
  DEFAULT_MARGIN = 54 # 0.75 inch margins

  def test_initialize_default_settings
    # Default page content width
    assert_equal(DEFAULT_PAGE_BOX.width - 2 * DEFAULT_MARGIN, @doc_builder.page_content_width, "Testing content width")

    # Default page box
    assert_equal(DEFAULT_PAGE_BOX, @doc_builder.page_box, "Testing page box")
  end

  def test_add_page_yields_builder
    @doc_builder.page do |page|
      assert_instance_of(CrossDoc::PageBuilder, page, "Testing page")
    end
  end

  def test_add_page
    @doc_builder.page do |page|
      # Do nothing
    end

    pages = @doc_builder.to_doc.pages
    assert_equal(1, pages.length, "Testing amount of pages")
    assert_instance_of(CrossDoc::Page, pages.first, "Testing first page")
  end

  def test_add_header_footer_yields_builder
    @doc_builder.header do |header|
      assert_instance_of(CrossDoc::NodeBuilder, header, "Testing header builder")
    end

    @doc_builder.header do |header|
      assert_instance_of(CrossDoc::NodeBuilder, header, "Testing footer builder")
    end
  end

  def test_empty_document
    doc = @doc_builder.to_doc

    assert_empty(doc.pages, "Testing pages")
    assert_empty(doc.images, "Testing images")

    assert_equal(DEFAULT_PAGE_BOX.width, doc.page_width, "Testing page width")
    assert_equal(DEFAULT_PAGE_BOX.height, doc.page_height, "Testing page height")

    assert_nil(doc.footer, "Testing nil document footer")
    assert_nil(doc.header, "Testing nil document header")
  end
end
