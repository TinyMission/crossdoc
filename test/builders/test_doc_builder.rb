# frozen_string_literal: true

require 'crossdoc/builder'
require 'minitest/autorun'

class DocBuilderTest < MiniTest::Spec
  before do
    @doc_builder = CrossDoc::Builder.new
  end

  DEFAULT_PAGE_BOX = Box.new(x: 0, y: 0, width: 612, height: 792) # Portrait letter paper
  DEFAULT_MARGIN = 54 # 0.75 inch margins

  describe 'upon initialization' do
    it 'must have a default page content width' do
      _(@doc_builder.page_content_width).must_equal(DEFAULT_PAGE_BOX.width - 2 * DEFAULT_MARGIN)
    end

    it 'must have a default page box' do
      _(@doc_builder.page_box).must_equal(DEFAULT_PAGE_BOX)
    end
  end

  describe 'when adding a page' do
    it 'must yield a page builder' do
      @doc_builder.page do |page|
        _(page).must_be_instance_of(CrossDoc::PageBuilder)
      end
    end
  end

  describe 'when adding a header' do
    it 'must yield a node builder' do
      @doc_builder.header do |header|
        _(header).must_be_instance_of(CrossDoc::NodeBuilder)
      end
    end
  end

  describe 'when adding a footer' do
    it 'must yield a node builder' do
      @doc_builder.footer do |footer|
        _(footer).must_be_instance_of(CrossDoc::NodeBuilder)
      end
    end
  end

  describe 'when building an empty document doc' do
    before do
      @doc = @doc_builder.to_doc
    end

    it 'must have no pages' do
      _(@doc.pages).must_be_empty
    end

    it 'must have no images' do
      _(@doc.images).must_be_empty
    end

    it 'must have the default page dimensions' do
      _(@doc.page_width).must_equal(DEFAULT_PAGE_BOX.width)
      _(@doc.page_height).must_equal(DEFAULT_PAGE_BOX.height)
    end

    it 'must have no footer or header' do
      _(@doc.footer).must_be_nil
      _(@doc.header).must_be_nil
    end
  end
end
