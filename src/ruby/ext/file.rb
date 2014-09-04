class File
  def self.split path
    [File.dirname(path), File.basename(path)]
  end
end
