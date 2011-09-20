#encoding: ascii-8bit
require 'fileutils'
require 'textpow'
require 'uv/render_processor'
require "uv/version"
require 'uv/utility'
require 'uv/engine' if defined?(Rails)


module Uv
  class << self
    attr_accessor :render_path, :theme_path, :syntax_path, :default_style, :syntaxes
  end

  self.syntax_path   = File.join(File.dirname(__FILE__), '..', 'syntax')
  self.render_path   = File.join(File.dirname(__FILE__), '..', 'render')
  #self.theme_path    = File.join(render_path, 'xhtml', 'files', 'css')
  self.theme_path    = File.join(File.dirname(__FILE__), '..', 'vendor', 'assets', 'stylesheets')
  self.default_style = 'mac_classic'
  self.syntaxes      = {}

  # Returns the root path for Uv ['bin','lib'...]
  def Uv.path
    result = []
    result << File.join(File.dirname(__FILE__), ".." )
  end

  # Returns the Textpow::SyntaxNode for this syntax; 
  # @raise ArgumentError if no syntax is found
  # Ex: syntax_node_for('ruby') => Textpow::SyntaxNode.load('ruby.syntax')
  def self.syntax_node_for(syntax)
    if !@syntaxes.key?(syntax)
      filename = File.join(@syntax_path, "#{syntax}.syntax")
      @syntaxes[syntax] = if File.exist?(filename)
        Textpow::SyntaxNode.load(filename)
      else
        false
      end
    end
    if !@syntaxes[syntax]
      raise ArgumentError, "No #{syntax}.syntax file in #{@syntax_path}"
    end
    @syntaxes[syntax]
  end

  # Copies files from the [ruby-uv/render/<arg1>/files/] to the <arg2> output directory
  def Uv.copy_files output, output_dir
    Uv.path.each do |dir|
      dir_name = File.join( dir, "render", output, "files" )
      FileUtils.cp_r( Dir.glob(File.join( dir_name, "." )), output_dir ) if File.exists?( dir_name )
    end
  end

  # Returns the list of file names[.syntax] in the syntax dir
  def Uv.syntaxes
    Dir.glob( File.join(@syntax_path, '*.syntax') ).collect do |f|
      File.basename(f, '.syntax')
    end
  end

  # Returns the list of .css files in the theme directory
  def Uv.themes
    Dir.glob( File.join(@theme_path, '*.css') ).collect do |f|
      File.basename(f, '.css')
    end
  end

  # Guesses the correct syntax based on the input files fileType.
  # If the FileType doesnt containt a valid syntax name, each syntax
  # has it's first line matched againts the the file's first line
  def Uv.syntax_for_file file_name
    init_syntaxes unless @syntaxes
    first_line = ""
    File.open( file_name, 'r' ) { |f|
      while (first_line = f.readline).strip.size == 0; end
    }
    result = []
    @syntaxes.each do |key, value|
      assigned = false
      if value.fileTypes
        value.fileTypes.each do |t|
          if t == File.basename( file_name ) || t == File.extname( file_name )[1..-1]
            result << [key, value]
            assigned = true
            break
          end
        end
      end
      unless assigned
        if value.firstLineMatch && value.firstLineMatch =~ first_line
          result << [key, value]
        end
      end
    end
    result
  end

  # Parses <arg1> text using RenderProcessor.load(Textpow::SyntaxNode.parse(text)), returns the vailid <output>
  def Uv.parse text, output = "xhtml", syntax_name = nil, line_numbers = false, render_style = nil, headers = false
    RenderProcessor.load(output, render_style, line_numbers, headers) do |processor|
      syntax_node_for(syntax_name).parse(text, processor)
    end.string
  end

  # Parses <arg1> text with Textpow::DebugProcessor, using the given syntax
  def Uv.debug text, syntax_name
    syntax_node_for(syntax_name).parse(text, Textpow::DebugProcessor.new)
  end

end