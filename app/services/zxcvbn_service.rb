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
        @tester ||= Zxcvbn::Tester.new
      end
    end
  end

  def initialize(password)
    @password = password
  end

  def complexity
    wxcvbn = compute_zxcvbn
    score = wxcvbn.score
    length = @password.blank? ? 0 : @password.length
    [score, length]
  end

  def score
    compute_zxcvbn.score
  end

  private

  def compute_zxcvbn
    self.class.tester.test(@password)
  end
end
