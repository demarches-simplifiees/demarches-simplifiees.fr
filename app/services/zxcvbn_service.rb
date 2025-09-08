# frozen_string_literal: true

class ZxcvbnService
  @tester_mutex = Mutex.new

  # Returns an Zxcvbn instance cached between classes instances and between threads.
  #
  # The tester weights ~20 Mo, and we'd like to save some memory – so rather
  # that storing it in a per-thread accessor, we prefer to use a mutex
  # to cache it between threads.

  def self.tester
    @tester_mutex.synchronize do
      @tester ||= Zxcvbn::Tester.new
    end
  end

  def self.complexity(password)= tester.test(password.to_s).score
end
