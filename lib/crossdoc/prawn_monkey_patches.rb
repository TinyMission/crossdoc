require 'prawn'

Prawn::Font::AFM.hide_m17n_warning = true

# monkey patch to skip invalid characters
class Prawn::Font::AFM
  def normalize_encoding(text)
    text.encode('windows-1252', invalid: :replace, undef: :replace, replace: '?')
  end
end
