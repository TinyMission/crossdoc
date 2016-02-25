require 'prawn'

module CrossDoc

  # utility methods for computing font metrics using Prawn's font system
  class FontMetrics

    @dummy_document = Prawn::Document.new

    def self.num_lines(text, width, font_size, font_name='Helvetica')
      font = @dummy_document.find_font font_name
      total_width = font.compute_width_of text, size: font_size
      (total_width / width.to_f).ceil
    end

  end

end