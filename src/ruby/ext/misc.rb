# cruby doesn't require this

class File
  def self.split path
    [File.dirname(path), File.basename(path)]
  end
end

class NilClass

  def <=>(o)
    o.is_a?(NilClass) ? 0 : nil
  end

  def =~(o)
    nil
  end

end

class Array

  def =~(o)
    nil
  end

  def to_ary
    to_a
  end

  # this is stupid

  alias_method 'eq_orig', '=='
  def ==(o)
    o.class == MiniRake::FileList ? o.==(self) : eq_orig(o)
  end

  alias_method 'spaceship_orig', '<=>'
  def <=>(o)
    o.class == MiniRake::FileList ? spaceship_orig(o.to_a) : spaceship_orig(o)
  end

  alias_method 'minus_orig', '-'
  def -(o)
    o.class == MiniRake::FileList ? minus_orig(o.to_a) : minus_orig(o)
  end

  alias_method 'amp_orig', '&'
  def &(o)
    o.class == MiniRake::FileList ? amp_orig(o.to_a) : amp_orig(o)
  end

end
