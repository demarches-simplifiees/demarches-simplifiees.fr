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
          record.errors[record.type_de_champ.libelle] << "La date de naissance ne correspond pas à ce numéro DN."
        else
          record.errors[record.type_de_champ.libelle] << "Le numéro de DN est inconnu de la CPS."
        end
      rescue => e
        # if CPS is not accessible, let user continue
        Rails.logger.error('Unable to contact CPS:' + e.message)
      end
    end
  end
end
