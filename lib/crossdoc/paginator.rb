# takes a document and spreads it into multiple pages
class CrossDoc::Paginator

  def initialize(options={})
    @options = {
        num_levels: 3
    }.merge options
  end

  # returns the node in parent.children that spans y
  def find_spanning_node(content_width, parent, y)
    return nil unless parent.children && parent.children.length > 0
    puts "looking for spanning node at #{y} with content_width #{content_width} in children #{parent.children.map{|n| "#{n.box.y}-#{n.box.bottom}"}.inspect}"
    parent.children.each do |node|
      if node.box.y <= y && node.box.bottom > y && (content_width-node.box.width)<1
        return node
      end
    end
    nil
  end

  def break_page(page, stack)
    original_child_count = page.children.count
    new_page = page.shallow_copy
    new_page.children = []

    before_parent = new_page
    after_parent = page
    stack.each do |after_node|
      end_of_stack = after_node == stack.last
      i = after_parent.children.index after_node
      puts "  after_node #{after_node.tag} is at index #{i}"

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
        before_parent.box.height = before_parent.children.last.box.bottom
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
        c.box.y -= dy
        if c != child
          c.box.y -=  height_diff
        end
      end
      unless parent == page
        new_height = parent.children.last.box.bottom
        height_diff = parent.box.height - new_height
        parent.box.height = new_height
      end
    end

    puts "split page with #{original_child_count} children into one with #{new_page.children.count} and one with #{page.children.count} with stack size #{stack.count}"

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
    content_width = doc.page_width - doc.page_margin.left - doc.page_margin.right
    pages = []

    while full_page
      y = 0
      stack = []
      0.upto(@options[:num_levels]) do |level|
        current_parent = stack.length > 0 ? stack.last : full_page
        span_node = find_spanning_node content_width, current_parent, content_height-y
        if span_node
          stack << span_node
          if level == @options[:num_levels]
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