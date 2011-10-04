require 'rubygems'
require 'test/unit'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'uv'

class UvTest < Test::Unit::TestCase
  def test_parses_blank
    assert_equal %(<pre class="mac_classic"></pre>), Uv.parse('', 'xhtml', 'css')
  end

  def test_debugs
    assert_kind_of Textpow::DebugProcessor, Uv.debug('', 'css')
  end

  def test_find_syntaxes_by_ext
    assert_instance_of Array, Uv.find_syntaxes_by_ext("css")
    assert_instance_of Textpow::SyntaxNode, Uv.find_syntaxes_by_ext("css").first
    assert_equal "CSS", Uv.find_syntaxes_by_ext("css").first.name
  end

end
