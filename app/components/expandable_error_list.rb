class ExpandableErrorList < ApplicationComponent
  def initialize(errors:)
    @errors = errors
  end

  def splitted_errors
    yield(Array(@errors[0..2]), Array(@errors[3..]))
  end
end
