# takes a document and spreads it into multiple pages
class CrossDoc::Paginator

  def initialize(num_levels: 3, max_pages: 10)
    @num_levels = num_levels
    @max_pages = max_pages
  end

  # returns the node in parent.children that spans y
  def find_spanning_node(content_height, parent, y)
    parent.children&.find do |node|
      next false unless node.box.present?

      box = node.box

      # Don't split child nodes that are taller than the entire document.
      # Otherwise, this algorithm will generate blank pages until the limit.
      next false if (box.bottom - box.y > content_height) && node.children&.empty?

      # look for a node that is entirely below y
      next true if box.y >= y

      # Don't split if the node significantly overlaps another in terms of height.
      # Assumes that all child nodes of a parent are fully contained in the
      # parent's bounding box.
      next false if parent.children.reject { _1 == node }.find do |other_node|
        next false unless other_node.box.present?

        other_box = other_node.box
        (box.y - other_box.y).abs <= 1 && (box.bottom - other_box.bottom).abs <= 1
      end

      # look for a node that spans y
      (box.y ... box.bottom).include? y
    end
  end

  def break_page(page, stack)
    new_page = page.shallow_copy
    new_page.children = []

    before_parent = new_page
    after_parent = page
    stack.each do |after_node|
      end_of_stack = after_node == stack.last
      i = after_parent.children.index after_node

      # add all nodes before the split to the before_parent
      if i > 0
        before_parent.children = after_parent.children[0..i-1]
      end

      # truncate the children before the after_node
      after_parent.children = after_parent.children[i..-1]

      # unless we're at the end of the stack, make a copy of the split node to use as before_parent
      unless end_of_stack
        last_before_node = after_node.shallow_copy
        before_parent.children << last_before_node
        last_before_node.children = []
        last_before_node.box = last_before_node.box.dup
      end

      # adjust the before_parent height to match the reduced number of children
      unless before_parent == new_page
        if before_parent.children.last&.box
          before_parent.box.height = before_parent.children.last.box.bottom
        else
          before_parent.box.height = 0
        end
      end

      # ordered list was broken up, so change the start of after_parent
      if after_parent.is_a?(CrossDoc::Node) && after_parent.tag&.downcase == 'ol' && before_parent.tag&.downcase == 'ol'
        after_parent.start = before_parent.children.count + before_parent.start - 1 # -1 for seemingly phantom list item
      end

      after_parent = after_node
      before_parent = before_parent.children.last
    end # after_node

    full_stack = [page] + stack
    height_diff = 0
    1.upto(stack.size).each do |i|
      child = full_stack[-i]
      parent = full_stack[-i-1]
      dy = child.box.y
      # if parent == page
      #   dy -= parent.padding.top
      # end
      parent.children.each do |c|
        next if c.box.nil?
        c.box.y -= dy
        if c != child
          c.box.y -=  height_diff
        end
        c.box.y = [c.box.y, 0].max
      end
      unless parent == page
        last_block_child = parent.children.reverse.find { |c| c.box.present? }
        new_height = last_block_child&.box&.bottom || 0
        height_diff = parent.box.height - new_height
        parent.box.height = new_height
      end
    end

    new_page
  end

  def run(doc)
    unless doc.pages.length == 1
      raise "Attempting to paginate a document with #{doc.pages.length} pages, it only works with one page for now"
    end
    unless doc.page_height and doc.page_height > 0
      raise 'In order to be paginated, documents need to have a non-zero page_height'
    end

    full_page = doc.pages.first
    unless full_page.children && full_page.children.length > 0 && full_page.children.first.box.height > 0
      return # empty document
    end

    content_height = doc.page_height - doc.page_margin.top - doc.page_margin.bottom
    if doc.header
      content_height -= doc.header.box.height
    end
    if doc.footer
      content_height -= doc.footer.box.height
    end
    pages = []

    page_num = 0
    while full_page && page_num < @max_pages
      page_num += 1
      y = 0
      stack = []
      0.upto @num_levels do |level|
        current_parent = stack.length > 0 ? stack.last : full_page

        span_node = find_spanning_node(content_height, current_parent, content_height - y)
        if span_node
          stack << span_node
          if level == @num_levels
            pages << break_page(full_page, stack)
            break
          else
            y += span_node.box.y
          end
        else # no span node
          if stack.length > 0
            pages << break_page(full_page, stack)
          else
            pages << full_page
            full_page = nil
          end
          break
        end
      end
    end

    doc.pages = pages

  end

end
