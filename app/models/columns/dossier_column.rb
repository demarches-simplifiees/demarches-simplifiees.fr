# frozen_string_literal: true

class Columns::DossierColumn < Column
  def value(dossier)
    case table
    when 'self'
      dossier.public_send(column)
    when 'etablissement'
      dossier.etablissement.public_send(column)
    when 'individual'
      dossier.individual.public_send(column)
    when 'groupe_instructeur'
      dossier.groupe_instructeur.label
    when 'followers_instructeurs'
      dossier.followers_instructeurs.map(&:email).join(' ')
    end
  end

  def dossier_column? = true
end
