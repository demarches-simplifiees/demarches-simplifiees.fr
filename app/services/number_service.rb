class NumberService
  def self.to_number(string)
    string.to_s if Float(string) rescue nil
  end
end
