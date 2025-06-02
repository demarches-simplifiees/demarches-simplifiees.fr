# frozen_string_literal: true

class Champs::NationaliteChamp < Champs::TextChamp
  def self.options
    APIGeo::API.nationalites.pluck(:nom)
  end

  def self.disabled_options
    options.filter { |v| (v =~ /^--.*--$/).present? }
  end
end
