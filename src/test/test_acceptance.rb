require_relative 'helper'
require_relative '../ruby/meta'

class TestAcceptance < Minitest::Test

  def setup
    @minirake = '../minirake'

    rm_rf $tmpdir
    Dir.mkdir $tmpdir
  end

  def teardown
    rm_rf $tmpdir
  end

  def test_env
    r = `#{@minirake} -V`
    assert r

    r = r.split "\n"
    assert_equal MiniRake::Meta::VERSION, r.first.split(':')[1].strip
    assert_equal true.to_s, r[1].split(':')[1].strip
    assert_match(/^mruby /, r[2].split(':')[1].strip)
  end

  def test_desc
    r = `#{@minirake} -C .. -T`
    assert r

    expected = <<EOF
clean
    clean compiled files
minirake
    build executable
EOF

    assert_equal expected.rstrip, r.split("\n")[1..-1].join("\n")
  end

  # a confusing behavior identical to rake
  # https://github.com/jimweirich/rake/issues/290
  def test_desc_dyn1
    r = `#{@minirake} -f fixtures/desc_dyn_task1.rb -T`
    assert r

    expected = <<EOF
dynamicTest
    test task
EOF

    assert_equal expected.rstrip, r.split("\n").join("\n")
  end

  def test_desc_dyn2
    r = `#{@minirake} -f fixtures/desc_dyn_task2.rb -T`
    assert r

    expected = <<EOF
default
    default task
dynamicTest
    a desc for a dynamic task
EOF

    assert_equal expected.rstrip, r.split("\n").join("\n")
  end

  def test_prereqs
    r = `#{@minirake} -C .. -P`
    assert r

    expected = <<EOF
MiniRake::FileTask bytecode.deps.c
    deps.rb
MiniRake::FileTask bytecode.main.c
    ruby/main.rb
MiniRake::Task clean
MiniRake::Task default
    minirake
MiniRake::FileTask deps.rb
    ruby/cloneable.rb
    ruby/ext/misc.rb
    ruby/ext/string.rb
    ruby/file_list.rb
    ruby/main.rb
    ruby/meta.rb
MiniRake::FileTask minirake
    bytecode.deps.o
    bytecode.main.o
    main.o
MiniRake::Task test
    minirake
EOF

    assert_equal expected.rstrip, r.split("\n")[1..-1].join("\n")
  end

  def test_compilation
    `#{@minirake} -C ..`
    `#{@minirake} -C .. clean`
    assert_equal 0, $?

    r = ''
    cd '..' do
      r = `rake 2>&1`
    end

    assert (r.size > 500)

    assert_equal 1, `#{@minirake} -C ..`.split("\n").size
  end

  def test_a_clo
    r = `#{@minirake} -C .. -A dummy -A obj -A rdeps`
    r = r.split("\n")[1..-1]

    assert_equal nil, (eval r[0])
    assert (eval r[1]).size >= 3
    assert_equal ["ruby/cloneable.rb",
                  "ruby/ext/misc.rb",
                  "ruby/ext/string.rb",
                  "ruby/file_list.rb",
                  "ruby/main.rb",
                  "ruby/meta.rb"], (eval r[2]).sort
  end

  def test_directory
    cd $tmpdir do
      assert_equal "mkdir -p qqq/www/eee\nok\n", `../#{@minirake} -f ../fixtures/directory.rb foo`
      assert_equal "ok\n",`../#{@minirake} -f ../fixtures/directory.rb foo`
    end
  end

  def test_fileutils
    cd $tmpdir do
      r = `../#{@minirake} -f ../fixtures/fileutils.rb`
      assert_equal "touch 1.txt\n", r
      assert File.exist? "1.txt"

      rm "1.txt"

      r = `../#{@minirake} -f ../fixtures/fileutils.rb -q`
      assert r.size == 0
      assert File.exist? "1.txt"

      rm "1.txt"

      r = `../#{@minirake} -f ../fixtures/fileutils.rb -n`
      assert_match(/^touch 1.txt/, r)
      refute File.exist? "1.txt"

      r = `../#{@minirake} -f ../fixtures/fileutils.rb -nq`
      refute_match(/touch 1.txt/, r)
      refute File.exist? "1.txt"
    end
  end

end
