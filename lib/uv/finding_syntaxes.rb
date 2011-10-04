module Uv

  def Uv.find_syntaxes_by_ext(ext)
    syntaxes = []
    if !@syntaxes.key?(ext)
      @syntaxes.each do |syntax_name, syntax_node|
        syntaxes << syntax_node if syntax_node.fileTypes && syntax_node.fileTypes.include?(ext)
      end
      filename = File.join(@syntax_path, "#{ext}.syntax")
      syntaxes << Textpow::SyntaxNode.load(filename) if File.exist?(filename)
    else
      syntaxes << @syntaxes[ext]
    end
    syntaxes
  end

  def Uv.find_syntaxes_by_first_line(first_line)
    syntaxes = []
    @syntaxes.each do |syntax_name, syntax_node|
      syntaxes << syntax_node if syntax_node.firstLineMatch && syntax_node.firstLineMatch =~ first_line
    end
    syntaxes
  end

  def Uv.find_syntaxes(extensions=[], first_line='')
    init_syntaxes unless @syntaxes
    syntaxes = []
    extensions.each do |ext|
      syntaxes += find_syntaxes_by_ext(ext)
    end
    syntaxes += find_syntaxes_by_first_line(first_line)
    syntaxes
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
      if syntax == '' or syntax.nil?
        puts "No syntax supplied, defaulting to 'plain_text' syntax"
        syntax = "plain_text"
      else
        raise ArgumentError, "Syntax not found.  No #{syntax}.syntax file in #{@syntax_path}"
      end
    end
    @syntaxes[syntax]
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

end