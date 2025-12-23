# frozen_string_literal: true

require 'minitest/autorun'
require 'crossdoc/builder'
require 'crossdoc/tree'
require 'prawn'

class NodeBuilderTest < Minitest::Test
  def test_create_div_creates_childless_div
    page = single_page do |page|
      page.div {}
    end

    node = page.children.first
    assert_equal('DIV', node.tag)
    assert_empty node.children
  end

  def test_create_node_creates_tags_and_attrs
    test_text = (0...rand(64)).map { rand(65..90).chr }.join
    page = single_page do |page|
      page.node('p', { text: test_text }) {}
    end

    node = page.children.first
    assert_equal('P', node.tag)
    assert_equal(test_text, node.text)
  end

  def test_border_attribute
    node = single_page do |page|
      page.div({
                 border: {
                   top: { width: 1, style: 'solid' },
                   left: { width: 2, style: 'dashed', color: '#FF0000' },
                   right: { width: 3, style: 'dotted', color: '#00FF00' },
                   bottom: { width: 4, color: '#0000FF' }
                 }
               }) {}
    end.children.first

    top = node.border.top
    left = node.border.left
    right = node.border.right
    bottom = node.border.bottom

    assert_equal(1, top.width)
    assert_equal('solid', top.style)
    assert_equal('#000000', top.color)

    assert_equal(2, left.width)
    assert_equal('dashed', left.style)
    assert_equal('#FF0000', left.color)

    assert_equal(3, right.width)
    assert_equal('dotted', right.style)
    assert_equal('#00FF00', right.color)

    assert_equal(4, bottom.width)
    assert_equal('solid', bottom.style)
    assert_equal('#0000FF', bottom.color)
  end

  def test_border_all_method
    single_page do |page|
      page.div do |node|
        node.border_all '1px solid'
      end
    end
  end

  private

  # Build a single page document, yielding a node builder.
  def single_page(&block)
    builder = CrossDoc::Builder.new
    builder.page(&block)
    builder.to_doc.pages.first
  end

  # Create a node builder with no associated document.
  def new_builder(opts) = CrossDoc::NodeBuilder.new(nil, opts)
end
