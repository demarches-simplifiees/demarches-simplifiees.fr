# Write the given objects to the standard output – except if Rake is configured
# to be quiet.
#
# This is useful when running tests (when Rake is configured to be quiet),
# to avoid spamming the output with extra informations.
def rake_puts(*args)
  if Rake.verbose
    puts(*args)
  end
end

def rake_print(*args)
  if Rake.verbose
    print(*args)
  end
end

class ProgressReport
  def initialize(total)
    @start = Time.zone.now
    rake_puts
    set_progress(total: total, count: 0)
  end

  def inc
    set_progress(count: @count + 1)
    if @per_10_000 % 10 == 0
      print_progress
    end
  end

  def finish
    if @count > 0 && @per_10_000 != 10_000
      set_progress(total: @count)
      print_progress
    end
    rake_puts
  end

  private

  def set_progress(total: nil, count: nil)
    if total.present?
      @total = total
    end
    if count.present?
      @count = count
      @total = [@count, @total].max
    end
    if @total&.nonzero?
      @per_10_000 = 10_000 * @count / @total
    end
  end

  def print_progress
    elapsed = Time.zone.now - @start
    percent = format('%5.1f%%', @per_10_000 / 100.0)
    total = @total.to_s
    count = @count.to_s.rjust(total.length)
    rake_print("\r#{percent} (#{count}/#{total}) [#{format_duration(elapsed)}/#{format_duration(elapsed * 10_000.0 / @per_10_000)}]")
  end

  def format_duration(seconds)
    if seconds.finite?
      Time.zone.at(seconds).utc.strftime('%H:%M:%S')
    else
      '--:--:--'
    end
  end
end
