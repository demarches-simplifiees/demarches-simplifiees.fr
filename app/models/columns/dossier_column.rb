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
    when 'dossier_labels'
      dossier.labels.map(&:name).join(' ')
    when 'followers_instructeurs'
      dossier.followers_instructeurs.map(&:email).join(' ')
    when 'traitements'
      dossier.traitements.map(&:instructeur_email).join(' ')
    end
  end

  def dossier_column? = true

  def filtered_ids(dossiers, values)
    case table
    when 'self'
      if type == :date || type == :datetime
        dates = values
          .filter_map { |v| Time.zone.parse(v).beginning_of_day rescue nil }

        dossiers.filter_by_datetimes(column, dates)
      elsif column == "state" && values.include?("pending_correction")
        dossiers.joins(:corrections).where(corrections: DossierCorrection.pending)
      elsif column == "state" && values.include?("en_construction")
        dossiers.where("dossiers.#{column} IN (?)", values).includes(:corrections).where.not(corrections: DossierCorrection.pending)
      elsif type == :integer
        dossiers.where("dossiers.#{column} IN (?)", values.filter_map { Integer(_1) rescue nil })
      else
        dossiers.where("dossiers.#{column} IN (?)", values)
      end
    when 'etablissement'
      if column == 'entreprise_date_creation'
        dates = values
          .filter_map { |v| v.to_date rescue nil }

        dossiers
          .includes(:etablissement)
          .where(etablissements: { column => dates })
      elsif type == :integer
        dossiers
          .includes(:etablissement)
          .where(etablissements: { column => values.filter_map { Integer(_1) rescue nil } })
      else
        dossiers
          .includes(:etablissement)
          .filter_ilike(table, column, values)
      end
    when 'followers_instructeurs'
      dossiers
        .includes(:followers_instructeurs)
        .joins('INNER JOIN users instructeurs_users ON instructeurs_users.id = instructeurs.user_id')
        .filter_ilike('instructeurs_users', :email, values) # ilike OK, user may want to search by *@domain
    when 'user', 'individual', 'traitements' # user_columns: [email], individual_columns: ['nom', 'prenom', 'gender']
      dossiers
        .includes(table)
        .filter_ilike(table, column, values) # ilike or where column == 'value' are both valid, we opted for ilike
    when 'dossier_labels'
      dossiers
        .joins(:dossier_labels)
        .where(dossier_labels: { label_id: values })
    when 'groupe_instructeur'
      dossiers
        .joins(:groupe_instructeur)
        .where(groupe_instructeur_id: values)
    when 'dossier_notifications'
      values << 'message_usager' if values.include?('message')
      values << 'message' if values.include?('message_usager')

      dossiers
        .joins(:dossier_notifications)
        .where(dossier_notifications: { notification_type: values })
    end.ids
  end
end
