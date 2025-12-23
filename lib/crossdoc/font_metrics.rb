require 'prawn'

module CrossDoc

  class FontMetrics

    @dummy_document = Prawn::Document.new

    # Compute the number of lines taken by a text string with the given font
    # after being wrapped at a given width.
    #
    # @param text [String] The text to compute.
    # @param width [Numeric] The width at which to wrap text.
    # @param font_size [Numeric] The font size in pixels (not points!)
    # @param font_name [String] The font family whose metrics to use
    # @returns [Integer] the number of lines taken by the wrapped text
    def self.num_lines(text, width, font_size, font_name='Helvetica')
      font = @dummy_document.find_font font_name

      words = text.split(/\s+/)
      word_widths = words.map{|w| font.compute_width_of(w, size: font_size)}
      space_width = font.compute_width_of(' ', size: font_size)

      total_width = word_widths.sum + space_width*(words.length-1)
      if total_width <= width
        return 1
      end

      lines = 1
      line_width = 0
      word_widths.each do |w|
        if line_width + w > width
          line_width = w + space_width
          lines += 1
        else
          line_width += w + space_width
        end
      end
      lines
    end

  end

end
