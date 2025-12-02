require_relative 'util'

class Numeric

  def inches
    self * 72.0
  end

end

module CrossDoc
  class Background
    include CrossDoc::Fields

    def initialize(attrs = {})
      assign_fields attrs
    end

    simple_fields %i(attachment color image position repeat)

    def color_no_hash
      self.color.gsub('#', '')[0..5]
    end
  end


  # represents a rectangular box
  class Box
    include CrossDoc::Fields

    def initialize(attrs = {width: 0, height: 0, x: 0, y: 0})
      assign_fields attrs
    end

    simple_fields %i(x y width height)

    def right
      self.x + self.width
    end

    def bottom
      self.y + self.height
    end

    def move_down(dy)
      self.y += dy
    end

    def dup
      Box.new x: self.x, y: self.y, width: self.width, height: self.height
    end

    def to_s
      "x: #{self.x}, y: #{self.y}, w: #{self.width}, h: #{self.height}"
    end

  end


  class BorderSide
    include CrossDoc::Fields

    def initialize(attrs = {width: 1, style: 'solid', color: '#000000'})
      assign_fields attrs
    end

    simple_fields %i(width style color)

    def color_no_hash
      self.color.gsub('#', '')[0..5]
    end

    def ==(other)
      return false unless other
      self.width == other.width && self.style == other.style && self.color == other.color
    end

    @possible_styles = %w(solid dashed dotted)

    # parses a CSS border string into a BorderSize
    def self.from_s(s)
      side = CrossDoc::BorderSide.new
      comps = s.split(/\s/)
      comps.each do |comp|
        if comp =~ /px$/
          side.width = comp.gsub('px', '').to_f
        elsif comp =~ /^#[\d[a-z][A-Z]]+$/
          side.color = comp
        elsif @possible_styles.index comp
          side.style = comp
        end
      end
      side
    end

  end


  class Border
    include CrossDoc::Fields

    def initialize(attrs = {top: nil, bottom: nil, left: nil, right: nil})
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

    simple_fields %i(color size weight decoration family style line_height letter_spacing align transform)

    def color_no_hash
      self.color.gsub('#', '')[0..5]
    end

    def transform_text(s)
      case @transform
        when 'capitalize'
          s.capitalize
        when 'uppercase'
          s.upcase
        when 'lowercase'
          s.downcase
        else
          s
      end
    end

    # one of the allowed default prawn font styles
    def prawn_style
      is_bold = self.weight == 'bold' || self.weight.to_i&.>=(700).is_true?
      is_italic = %w[italic oblique].include? self.style

      is_bold ?
        (is_italic ? :bold_italic : :bold) :
        (is_italic ? :italic : :normal)
    end

    def self.default(modifiers={})
      args = {family: 'helvetica,sans-serif', color: '#000000', size: 12, weight: 'normal', align: :left, line_height: 16}.merge modifiers
      # guess as a good line height
      unless modifiers.has_key? :line_height
        args[:line_height] = (1.4 * args[:size]).round.to_i
      end
      CrossDoc::Font.new args
    end

  end

  # used for both margin and padding
  class Margin
    include CrossDoc::Fields

    def initialize(attrs = {top: 0, left: 0, right: 0, bottom: 0})
      assign_fields attrs
    end

    simple_fields %i(top right bottom left)

    def set_all(d)
      @top = d
      @left = d
      @right = d
      @bottom = d
      self
    end

    def css_array
      [self.top, self.right, self.bottom, self.left]
    end

    def to_s
      if [self.top, self.left, self.right, self.bottom].uniq.length == 1
        "all: #{self.top}"
      elsif self.top == self.bottom && self.left == self.right
        "vert: #{self.top}, horiz: #{self.left}"
      else
        "top: #{self.top}, left: #{self.left}, right: #{self.right}, bottom: #{self.bottom}"
      end

    end
  end

end
