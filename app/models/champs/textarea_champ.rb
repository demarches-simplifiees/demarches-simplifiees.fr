# frozen_string_literal: true

class Champs::TextareaChamp < Champs::TextChamp
  def remaining_characters
    character_limit_base - character_count if character_count >= character_limit_threshold_75
  end

  def excess_characters
    character_count - character_limit_base if character_count > character_limit_base
  end

  def character_limit_info?
    analyze_character_count == :info
  end

  def character_limit_warning?
    analyze_character_count == :warning
  end

  def character_limit_base
    character_limit&.to_i
  end

  private

  def character_count
    return value&.bytesize
  end

  def character_limit_threshold_75
    character_limit_base * 0.75
  end

  def analyze_character_count
    if character_limit? && character_count.present?
      if character_count > character_limit_base
        return :warning
      elsif character_count >= character_limit_threshold_75
        return :info
      end
    end
  end
end
