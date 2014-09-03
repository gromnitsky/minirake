require 'fileutils'
include FileUtils

require 'minitest/autorun'

Dir.chdir __dir__
$tmpdir = '.tmp'
