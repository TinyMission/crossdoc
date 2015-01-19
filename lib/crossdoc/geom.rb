require 'util'

module CrossDoc
  class Background
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(attachment color image position repeat)

    def color_no_hash
      self.color.gsub('#', '')
    end
  end


  # represents a rectangular box
  class Box
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(x y width height)

    def right
      self.x + self.width
    end

  end


  class BorderSide
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(width style color)

    def color_no_hash
      self.color.gsub('#', '')
    end

    def ==(other)
      return false unless other
      self.width == other.width && self.style == other.style && self.color == other.color
    end
  end


  class Border
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    object_field :top, BorderSide
    object_field :right, BorderSide
    object_field :bottom, BorderSide
    object_field :left, BorderSide

    def is_equal?
      (self.top == self.right) && (self.bottom == self.left) &&
          (self.top == self.bottom)
    end
  end


  class Font
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(color size weight decoration family style line_height align)

    def color_no_hash
      self.color.gsub('#', '')
    end
  end


  class Margin
    include CrossDoc::Fields

    def initialize(attrs)
      assign_fields attrs
    end

    simple_fields %i(top right bottom left)

    def css_array
      [self.top, self.right, self.bottom, self.left]
    end
  end

end
