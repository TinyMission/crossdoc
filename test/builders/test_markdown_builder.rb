# frozen_string_literal: true

require 'crossdoc/markdown_builder'
require 'crossdoc/builder'
require 'minitest/autorun'

class TestMarkdownBuilder < Minitest::Test
  def setup
    @node_builder = CrossDoc::NodeBuilder.new(nil, { tag: 'DIV' })
    @builder = CrossDoc::MarkdownBuilder.new(@node_builder)
  end

  def test_render_header
    children = build <<~MARKDOWN
    # Test Heading 1
   
    ## Test Heading 2

    ### Test Heading 3

    #### Test Heading 4

    ##### Test Heading 5

    ###### Test Heading 6
    MARKDOWN

    assert_equal(6, children.length, "Testing number of children for: #{children}")

    children.each_with_index do |heading, i|
      assert_equal("H#{i + 1}", heading.tag, "Testing tag for H#{i + 1}")
      assert_equal("Test Heading #{i + 1}", heading.text, "Testing text for H#{i + 1}")
    end
  end

  def test_render_paragraph
    children = build 'Test paragraph please ignore.'
    assert_equal(1, children.length, "Testing number of children: #{children}")
    paragraph = children.first
    assert_equal('P', paragraph.tag, "Testing tag type")
    assert_equal('Test paragraph please ignore.', paragraph.text, "Testing text content")
  end

  def test_render_multiline_paragraph
    children = build <<~MARKDOWN
      Test Paragraph
      Please Ignore
    MARKDOWN
    assert_equal(1, children.length, "Testing number of children: #{children}")
    paragraph = children.first
    assert_equal('P', paragraph.tag, "Testing tag type")
    assert_equal("Test Paragraph\nPlease Ignore", paragraph.text, "Testing text content")
  end

  def test_render_formatted_paragraph
    children = build 'This is a <i>test</i>.'
    assert_equal(1, children.length, "Testing number of children: #{children}")
    paragraph = children.first
    assert_equal('P', paragraph.tag, "Testing tag type")
    assert_equal('This is a <i>test</i>.', paragraph.text, "Testing text content")
  end

  def test_render_ordered_list
    children = build <<~MARKDOWN
      1. Item 1
      2. Item 2
      3. Item 3
    MARKDOWN
    assert_equal(1, children.length, "Testing number of children: #{children}")
    ordered_list = children.first
    assert_equal('OL', ordered_list.tag, "Testing tag type")
    list_items = ordered_list.children
    assert_equal(3, list_items.length, "Testing list length")
    list_items.each_with_index do |item, i|
      assert_equal('LI', item.tag, "Testing list item type (item #{i})")
      assert_equal("Item #{i + 1}", item.text, "Testing list text content (item #{i})")
    end
  end

  def test_render_unordered_list
    children = build <<~MARKDOWN
      * Item 1
      * Item 2
      * Item 3
    MARKDOWN
    assert_equal(1, children.length, "Testing number of children: #{children}")
    ordered_list = children.first
    assert_equal('UL', ordered_list.tag, "Testing tag type")
    list_items = ordered_list.children
    assert_equal(3, list_items.length, "Testing list length")
    list_items.each_with_index do |item, i|
      assert_equal('LI', item.tag, "Testing list item type (item #{i})")
      assert_equal("Item #{i + 1}", item.text, "Testing list text content (item #{i})")
    end
  end

  # TODO: Add test for nested lists when support is added.

  def test_render_simple_table
    children = build <<~MARKDOWN
      | C1R1 | C2R1 |
      | C1R2 | C2R2 |
    MARKDOWN
    assert_equal(1, children.length, "Testing number of children: #{children}")
    table = children.first
    assert_equal('TABLE', table.tag, "Testing table tag")
    table_children = table.children
    assert_equal(1, table_children.length, 'Testing immediate table children')
    table_body = table_children.first
    assert_equal('TBODY', table_body.tag, 'Testing table body tag')
    rows = table_body.children
    rows.each_with_index do |row, row_index|
      assert_equal('TR', row.tag, "Testing table row tag (row #{row_index})")
      cells = row.children
      assert_equal(2, cells.length, "Testing table column count (row #{row_index})")
      cells.each_with_index do |cell, column_index|
        assert_equal('TD', cell.tag, "Testing table cell tag (row #{row_index}, column #{column_index})")
        assert_empty(cell.children, "Testing table cell children (row #{row_index}, column #{column_index})")
        assert_equal("C#{column_index + 1}R#{row_index + 1}", cell.text, "Testing table text (row #{row_index + 1}, column #{column_index + 1})")
      end
    end
  end

  private

  def build(markdown)
    @builder.build markdown
    @node_builder.to_node.children
  end
end
