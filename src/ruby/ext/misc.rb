if RUBY_ENGINE == 'mruby'

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

    alias_method '__ary_eq_ORIG', '__ary_eq'
    def __ary_eq(o)
      o.klass == MiniRake::FileList ? __ary_eq_ORIG(o.to_a) : __ary_eq_ORIG(o)
    rescue
      __ary_eq_ORIG(o)
    end

    alias_method '__ary_cmp_ORIG', '__ary_cmp'
    def __ary_cmp(o)
      o.klass == MiniRake::FileList ? __ary_cmp_ORIG(o.to_a) : __ary_cmp_ORIG(o)
    rescue
      __ary_cmp_ORIG(o)
    end

  end

end
