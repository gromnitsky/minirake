def mruby?
  RUBY_ENGINE == 'mruby'
end

if mruby?
  $testunit_class = MTest::Unit::TestCase

  def __dir__
    File.dirname __FILE__
  end

  File::ALT_SEPARATOR = nil

  module MTest
    module Assertions
      alias assert_raises assert_raise
    end
  end

  include FileUtilsSimple

else
  require 'fileutils'
  include FileUtils
  require 'minitest/autorun'
  $testunit_class = Minitest::Test
end

Dir.chdir __dir__
$tmpdir = '.tmp'
