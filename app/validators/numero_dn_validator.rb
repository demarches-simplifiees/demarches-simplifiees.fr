# frozen_string_literal: true

class NumeroDnValidator < ActiveModel::Validator
  def validate(record)
    # we validate the dn against CPS Web Service
    # As we are in a UI, if CPS WS doesn't answer, we continue
    dn = record.numero_dn
    ddn = record.date_de_naissance
    if dn.present? && ddn.present?
      begin
        result = check_dn(ddn, dn)
        case result[dn]
        when 'true'
          # everything is good
        when 'false'
          record.errors.add(:date_de_naissance, :inconsistent_date)
        else
          record.errors.add(:value, :unknown_dn)
        end
      rescue
        record.errors.add(:value, :service_unavailable)
      end
    end
  end

  private

  def check_dn(ddn, dn)
    cache_key = "#{dn}-#{ddn}"
    result = Rails.cache.read(cache_key)
    return result unless result.nil?

    # Si pas dans le cache, faire l'appel à l'API
    result = APICps::API.new().verify({ dn => ddn })

    Rails.cache.write(cache_key, result, expires_in: 24.hours)
    result
  end
end
