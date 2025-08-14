require_relative './util'

module CrossDoc

  class Styler

    DEFAULT_STYLE = {
      FOOTER_LEFT: {
        font: { size: 10 }
      },
      FOOTER_CENTER: {
        font: { size: 10, align: 'center' }
      },
      FOOTER_RIGHT: {
        font: { size: 10, align: 'right' }
      },
      H1: {
        font: { size: 32 },
        margin: {bottom: 8}
      },
      H2: {
        font: { size: 26 },
        margin: {bottom: 8}
      },
      H3: {
        font: { size: 20 },
        margin: {bottom: 8}
      },
      P: {
        font: { size: 12 },
        margin: {bottom: 12}
      },
      UL: {
        margin: {bottom: 12, left: 20}
      },
      OL: {
        margin: {bottom: 12, left: 20}
      },
      LI: {
        font: {
          size: 12,
          line_height: 24
        }
      },
      TABLE: {
        border: '1px solid',
        margin: { bottom: 0.1.inches }
      },
      TH: {
        font: { size: 13, align: 'center' },
      },
      THEAD: {
        border: { bottom: '0.2px solid' },
      },
      TR: {
        border: { bottom: '0.2px solid' },
      },
      TD: {
        margin: {
          bottom: 1,
          top: 1,
          left: 8,
          right: 8
        },
        font: { size: 9, align: 'center' }
      }
    }

    def initialize(styles)
      @styles = DEFAULT_STYLE.deep_merge styles.sanitize_keys
      @fonts = @styles[:FONTS] || {}

      # apply the default font
      default_font_name = nil
      @fonts.each do |name, data|
        if data[:default]
          default_font_name = name.to_s
          break
        end
      end
      if default_font_name
        @styles.each do |key, data|
          if data[:font]
            data[:font][:family] ||= default_font_name
          else # no font specified
            data[:font] = {family: default_font_name}
          end
        end
      end
    end

    def style_border(node, border_value)
      if border_value.is_a? Hash
        raw_border = { top: '0', right: '0', bottom: '0', left: '0' }.merge(border_value)
        node.border_left raw_border[:left]
        node.border_right raw_border[:right]
        node.border_top raw_border[:top]
        node.border_bottom raw_border[:bottom]
      elsif border_value.is_a? String
        node.border_all border_value
      end
    end

    # styles a builder node with the given tag (uses the node's tag by default)
    def style_node(node, tag=nil)
      tag = (tag ||node.tag).to_s.upcase.to_sym
      node_style = @styles[tag] || {}

      node.default_font node_style[:font] || {}
      style_border(node, node_style[:border]) if node_style[:border].present?
      node.push_min_height node_style[:min_height] || 0

      unless node_style.has_key? :margin_cache
        raw_margin = {top: 0, right: 0, bottom: 0, left: 0}.merge (node_style[:margin] || {})
        node_style[:margin_cache] = Margin.new raw_margin
      end
      node.margin = node_style[:margin_cache]

      unless node_style.has_key? :padding_cache
        raw_padding = {top: 0, right: 0, bottom: 0, left: 0}.merge (node_style[:padding] || {})
        node_style[:padding_cache] = Margin.new raw_padding
      end
      node.padding = node_style[:padding_cache]
    end


    # registers the fonts defined in the FONTS tag of the styles hash with the given renderer
    def register_fonts(renderer)
      @fonts.each do |name, data|
        renderer.register_font_family name.to_s, data
      end
    end

  end

end
