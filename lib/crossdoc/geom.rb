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
      self.color.gsub('#', '')
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

    def move_down(dy)
      self.y += dy
    end

  end


  class BorderSide
    include CrossDoc::Fields

    def initialize(attrs = {width: 1, style: 'solid', color: '#000000ff'})
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

    @possible_styles = %w(solid dashed dotted)

    # parses a CSS border string into a BorderSize
    def self.from_s(s)
      side = CrossDoc::BorderSide.new
      comps = s.split /\s/
      comps.each do |comp|
        if comp =~ /px$/
          side.width = comp.gsub('px', '').to_f
        elsif comp =~ /^#[\d\w]+$/
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

    simple_fields %i(color size weight decoration family style line_height align transform)

    def color_no_hash
      self.color.gsub('#', '')
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
      if self.weight == 'bold'
        if self.style == 'italic'
          :bold_italic
        else
          :bold
        end
      else # not bold
        if self.style == 'italic'
          :italic
        else
          :normal
        end
      end
    end

    def self.default(modifiers)
      args = {family: 'helvetica,sans-serif', color: '#000000ff', size: 12, weight: 'normal', align: :left, line_height: 16}.merge modifiers
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
    end

    def css_array
      [self.top, self.right, self.bottom, self.left]
    end
  end

end
