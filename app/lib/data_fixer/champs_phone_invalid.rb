# frozen_string_literal: true

class DataFixer::ChampsPhoneInvalid
  def self.fix(phones_string)
    phone_candidates = phones_string
      .split(/-/)
      .map { |phone_with_space| phone_with_space.gsub(/\s/, '') }

    phone_candidates.find { |phone| phone.start_with?(/0(6|7)/) } || phone_candidates.first
  end

  def self.fixable?(phones_string)
    /-/.match?(phones_string)
  end
end
