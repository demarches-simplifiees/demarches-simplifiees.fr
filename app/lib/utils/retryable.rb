module Utils
  module Retryable
    # usage:
    # max_attempt : retry count
    # errors : only retry those errors
    # with_retry(max_attempt: 10, errors: [StandardError]) do
    #   do_something_which_can_fail
    # end
    def with_retry(max_attempt: 1, errors: [StandardError], &block)
      limiter = 0
      begin
        yield
      rescue *errors
        limiter += 1
        retry if limiter <= max_attempt
        raise
      end
    end
  end
end
