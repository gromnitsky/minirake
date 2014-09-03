require_relative 'helper'
require_relative '../ruby/meta'

class TestDepsWalk < Minitest::Test
  def setup
    @minirake = '../minirake'
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
    Dir.chdir '..' do
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
                  "ruby/ext/string.rb",
                  "ruby/file_list.rb",
                  "ruby/main.rb",
                  "ruby/meta.rb"], (eval r[2]).sort
  end
end
