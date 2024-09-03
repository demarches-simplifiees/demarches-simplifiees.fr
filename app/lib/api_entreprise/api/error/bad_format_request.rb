# frozen_string_literal: true

class APIEntreprise::API::Error::BadFormatRequest < APIEntreprise::API::Error
  def network_error?
    false
  end
end
