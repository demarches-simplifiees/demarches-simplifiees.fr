# frozen_string_literal: true

class SimpleFormattedChampValidator < ActiveModel::Validator
  TIMEOUT = 1.second.freeze

  def validate(record)
    letters_accepted = string_to_bool(options[:letters_accepted]) || string_to_bool(record.letters_accepted)
    numbers_accepted = string_to_bool(options[:numbers_accepted]) || string_to_bool(record.numbers_accepted)
    special_characters_accepted = string_to_bool(options[:special_characters_accepted]) || string_to_bool(record.special_characters_accepted)
    min_character_length = options[:min_character_length] || record.min_character_length
    max_character_length = options[:max_character_length] || record.max_character_length

    if record.value.present?
      if !letters_accepted
        if record.value.match?(Regexp.new(/[\p{L}\p{M}]/, timeout: TIMEOUT))
          record.errors.add(:value, :letters_forbidden)
        end
      end

      if !numbers_accepted
        if record.value.match?(Regexp.new(/\d/, timeout: TIMEOUT))
          record.errors.add(:value, :numbers_forbidden)
        end
      end

      if !special_characters_accepted
        if record.value.match?(Regexp.new(/[^\p{L}\p{M}\d]/, timeout: TIMEOUT))
          record.errors.add(:value, :special_characters_forbidden)
        end
      end

      if min_character_length
        if record.value.length < min_character_length.to_i
          record.errors.add(:value, :min_character_length_rule, min: min_character_length)
        end
      end

      if max_character_length
        if record.value.length > max_character_length.to_i
          record.errors.add(:value, :max_character_length_rule, max: max_character_length)
        end
      end
    end
  rescue Regexp::TimeoutError
    record.errors.add(:expression_reguliere, :evil_regexp)
  end

  private

  def string_to_bool(s)
    ActiveModel::Type::Boolean.new.cast(s)
  end
end
