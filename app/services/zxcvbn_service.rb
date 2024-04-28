# frozen_string_literal: true

class ZxcvbnService
  @tester_mutex = Mutex.new

  class << self
    # Returns an Zxcvbn instance cached between classes instances and between threads.
    #
    # The tester weights ~20 Mo, and we'd like to save some memory – so rather
    # that storing it in a per-thread accessor, we prefer to use a mutex
    # to cache it between threads.
    def tester
      @tester_mutex.synchronize do
        @tester ||= build_tester
      end
    end

    private

    # Returns a fully initializer tester from the on-disk dictionary.
    #
    # This is slow: loading and parsing the dictionary may take around 1s.
    def build_tester
      dictionaries = YAML.safe_load(Rails.root.join("config", "initializers", "zxcvbn_dictionnaries.yaml").read)

      tester = Zxcvbn::Tester.new
      tester.add_word_lists(dictionaries)
      tester
    end
  end

  def initialize(password)
    @password = password
  end

  def complexity
    wxcvbn = compute_zxcvbn
    score = wxcvbn.score
    length = @password.blank? ? 0 : @password.length
    vulnerabilities = wxcvbn.match_sequence.map { |m| m.matched_word.nil? ? m.token : m.matched_word }.filter { |s| s.length > 2 }.join(', ')
    [score, vulnerabilities, length]
  end

  def score
    compute_zxcvbn.score
  end

  private

  def compute_zxcvbn
    self.class.tester.test(@password)
  end
end
