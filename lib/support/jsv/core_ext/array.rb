class Array
  def to_jsv
    "[" + reject(&:nil?).map(&:to_jsv).join(",") + "]"
  end
end
