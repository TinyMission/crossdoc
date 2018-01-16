require 'optparse'

module CrossDoc

  # stand-alone application to convert documents between CrossDoc-supported formats
  class Converter

    def initialize(args)
      options = {}

      @verbose = false
      output = nil

      OptionParser.new do |opts|
        opts.banner = 'Usage: crossdoc-convert <input-path> [options] -o <output-path>'

        opts.on('-o', '--output PATH', 'The path of the output file, should be .json or .pdf') do |out|
          output = out
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

      puts "#{options.count} options"
      puts options

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

      builder = Builder.new
      builder.page do |page|
        page.markdown raw
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
      renderer = CrossDoc::PdfRenderer.new doc
      renderer.to_pdf path
    end

  end

end