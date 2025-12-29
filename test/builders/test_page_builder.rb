# frozen_string_literal: true

require 'crossdoc/builder'
require 'minitest/autorun'

class PageBuilderTest < Minitest::Test
  def setup
    @page_builder = CrossDoc::PageBuilder.new(nil, {})
  end

  def empty_page_has_no_children
    assert_empty @page_builder.to_page.children
  end
end
