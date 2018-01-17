require 'optparse'
require 'yaml'

module CrossDoc

  # stand-alone application to convert documents between CrossDoc-supported formats
  class Converter

    def initialize(args)
      @options = {
          paginate: 4
      }

      @verbose = false
      @has_footer = false
      output = nil

      OptionParser.new do |opts|
        opts.banner = 'Usage: crossdoc-convert <input-path> [options] -o <output-path>'

        opts.on('-o', '--output PATH', 'The path of the output file, should be .json or .pdf') do |out|
          output = out
        end

        opts.on('-s', '--style PATH', 'The path to a yaml file containing styling information') do |style_path|
          @options[:style_path] = style_path
        end

        opts.on('-lf', '--left-footer', 'Text to appear in the left side of the footer') do |lf|
          @options[:left_footer] = lf
          @has_footer = true
        end
        opts.on('-cf', '--center-footer', 'Text to appear in the center of the footer') do |cf|
          @options[:center_footer] = cf
          @has_footer = true
        end
        opts.on('-rf', '--right-footer', 'Text to appear in the right side of the footer') do |rf|
          @options[:right_footer] = rf
          @has_footer = true
        end

        opts.on('-v', '--verbose', 'Run verbosely') do |v|
          @verbose = true
        end

        opts.on_tail('-h', '--help', 'Show this message') do
          puts opts
          exit
        end
        if args.empty?
          puts opts
          exit
        end

      end.parse!(args)

      if args.count > 1
        puts 'Please provide only one input!'
        exit
      end

      puts "#{@options.count} options"
      puts @options

      begin
        run args.first, output
      rescue => ex
        puts ex.message
        if @verbose
          ex.backtrace.each do |line|
            puts line
          end
        end
      end
    end

    def run(input, output)
      # load input
      input_ext = input.split('.').last.downcase
      doc = case input_ext
              when 'md', 'markdown'
                load_markdown input
              when 'json'
                load_json input
              else
                raise "Unknown input extension .#{input_ext}, must be .md or .json"
            end

      # paginate
      CrossDoc::Paginator.new(num_levels: @options[:paginate]).run doc

      # write the output
      output_ext = output.split('.').last.downcase
      case output_ext
        when 'json'
          write_json doc, output
        when 'pdf'
          write_pdf doc, output
        else
          raise "Unknown output extension .#{output_ext}, must be .json or .pdf"
      end
      write_json doc, output.gsub('pdf', 'json')
    end


    private


    def log(message)
      if @verbose
        puts message
      end
    end


    def load_markdown(path)
      log "Loading markdown from #{path}"

      raw = File.read path

      # read the styles
      styles = {}
      if @options[:style_path]
        styles = YAML.load_file @options[:style_path]
      end
      @styler = Styler.new styles

      builder = Builder.new
      builder.page do |page|
        page.markdown raw, styles
      end

      # apply footer
      if @has_footer
        builder.footer do |footer|
          footer.div do |left_col|
            left_col.text = @options[:left_footer] || ''
            @styler.style_node left_col, :FOOTER_LEFT
          end
          footer.div do |center_col|
            center_col.text = @options[:center_footer] || ''
            @styler.style_node center_col, :FOOTER_CENTER
          end
          footer.div do |right_col|
            right_col.text = @options[:right_footer] || ''
            @styler.style_node right_col, :FOOTER_RIGHT
          end
        end
      end

      builder.to_doc
    end

    def load_json(path)
      Document.from_file path
    end

    def write_json(doc, path)
      log "Writing JSON document to #{path}"
      File.open(path, 'wt') do |f|
        f.write JSON.pretty_generate(doc.to_raw)
      end
    end

    def write_pdf(doc, path)
      log "Writing PDF document to #{path}"
      renderer = CrossDoc::PdfRenderer.new  doc
      renderer.to_pdf path
    end

  end

end