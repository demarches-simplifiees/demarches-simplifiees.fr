class NumeroDnValidator < ActiveModel::Validator
  def validate(record)
    # we validate the dn against CPS Web Service
    # As we are in a UI, if CPS WS doesn't answer, we continue
    dn  = record.numero_dn
    ddn = record.date_de_naissance
    if dn.present? && ddn.present?
      begin
        result = APICps::API.new().verify({ dn => ddn })
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
end
