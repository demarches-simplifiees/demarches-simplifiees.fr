# frozen_string_literal: true

class PasswordComplexityComponent < ApplicationComponent
  def initialize(length: nil, min_length: nil, score: nil, min_complexity: nil)
    @length = length
    @min_length = min_length
    @score = score
    @min_complexity = min_complexity
  end

  private

  def filled?
    !@length.nil? || !@score.nil?
  end

  def alert_classes
    class_names(
      "fr-alert": true,
      "fr-alert--sm": true,
      "fr-alert--info": !success?,
      "fr-alert--success": success?
    )
  end

  def success?
    return false if !filled?

    @length >= @min_length && @score >= @min_complexity
  end

  def complexity_classes
    [
      "password-complexity fr-mt-2w fr-mb-1w",
      filled? ? "complexity-#{@length < @min_length ? @score / 2 : @score}" : nil
    ]
  end

  def title
    return t(".title.empty") if !filled?

    return t(".title.too_short", min_length: @min_length) if @length < @min_length

    case @score
    when 0..1
      return t(".title.weakest")
    when 2...@min_complexity
      return t(".title.weak")
    when @min_complexity...4
      return t(".title.passable")
    else
      return t(".title.strong")
    end
  end

  def heading_level
    controller_name == 'passwords' && action_name == 'edit' ? 'h2' : 'h3'
  end
end
