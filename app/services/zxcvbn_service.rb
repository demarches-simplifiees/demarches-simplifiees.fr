class ZxcvbnService
  def initialize(password)
    @password = password
  end

  def complexity
    wxcvbn = compute_zxcvbn
    score = wxcvbn.score
    length = @password.blank? ? 0 : @password.length
    vulnerabilities = wxcvbn.match_sequence.map { |m| m.matched_word.nil? ? m.token : m.matched_word }.select { |s| s.length > 2 }.join(', ')
    [score, vulnerabilities, length]
  end

  def score
    compute_zxcvbn.score
  end

  private

  def compute_zxcvbn
    Zxcvbn.test(@password, [], ZXCVBN_DICTIONNARIES)
  end
end
