class PhoneSyntaxCheckerService
  def self.fr_regex
    fr_prefix = '(?:0|[+(]*33\)?\s*)[1234567]'
    fr_pair = '(?:[\\s.-]?\\d{2})'
    "(?:#{fr_prefix}#{fr_pair}{4})"
  end

  def self.pf_regex
    pf_prefix = '(?:[(+]*689\)?\s*)?(?:40|49|87|88|89)'
    pf_digit = '(?:[-\s\.]?[0-9])'
    "(?:#{pf_prefix}#{pf_digit}{6})"
  end

  def self.regex
    "#{pf_regex}|#{fr_regex}"
  end

  def self.is_france_number?(number)
    number.match("^#{fr_regex}$").present?
  end

  def self.is_polynesian_number?(number)
    number.match("^#{pf_regex}$").present?
  end

  def self.is_french_or_polynesian_number?(number)
    number.match("^(?:#{fr_regex}|#{pf_regex})$").present?
  end
end
