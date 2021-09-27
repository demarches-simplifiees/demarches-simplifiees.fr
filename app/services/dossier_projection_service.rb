class DossierProjectionService
  class DossierProjection < Struct.new(:dossier, :columns)
  end

  TABLE = 'table'
  COLUMN = 'column'

  # Returns [DossierProjection(dossier, columns)] ordered by dossiers_ids
  # and the columns orderd by fields.
  #
  # It tries to be fast by using `pluck` (or at least `select`)
  # to avoid deserializing entire records.
  #
  # It stores its intermediary queries results in an hash in the corresponding field.
  # ex: field_email[:id_value_h] = { dossier_id_1: email_1, dossier_id_3: email_3 }
  #
  # Those hashes are needed because:
  # - the order of the intermediary query results are unknown
  # - some values can be missing (if a revision added or removed them)
  def self.project(dossiers_ids, fields)
    champ_fields, other_fields = fields
      .partition { |f| ['type_de_champ', 'type_de_champ_private'].include?(f[TABLE]) }

    if champ_fields.present?
      Champ
        .includes(:type_de_champ)
        .where(
          # as querying the champs table is costly
          # we fetch all the requested champs at once
          types_de_champ: { stable_id: champ_fields.map { |f| f[COLUMN] } },
          dossier_id: dossiers_ids
        )
        .select(:dossier_id, :value, :type_de_champ_id, :stable_id) # we cannot pluck :value, as we need the champ.to_s method
        .group_by(&:stable_id) # the champs are redispatched to their respective fields
        .map do |stable_id, champs|
        field = champ_fields.find { |f| f[COLUMN] == stable_id.to_s }
        field[:id_value_h] = champs.to_h { |c| [c.dossier_id, c.to_s] }
      end
    end

    other_fields.each do |field|
      field[:id_value_h] = case field[TABLE]
      when 'self'
        Dossier
          .where(id: dossiers_ids)
          .pluck(:id, field[COLUMN].to_sym)
          .to_h { |id, col| [id, col&.strftime('%d/%m/%Y')] }
      when 'user'
        Dossier
          .joins(:user)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, users.email')
          .to_h
      when 'individual'
        Individual
          .where(dossier_id: dossiers_ids)
          .pluck(:dossier_id, field[COLUMN].to_sym)
          .to_h
      when 'etablissement'
        Etablissement
          .where(dossier_id: dossiers_ids)
          .pluck(:dossier_id, field[COLUMN].to_sym)
          .to_h
      when 'groupe_instructeur'
        Dossier
          .joins(:groupe_instructeur)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, groupe_instructeurs.label')
          .to_h
      when 'followers_instructeurs'
        Follow
          .active
          .joins(instructeur: :user)
          .where(dossier_id: dossiers_ids)
          .pluck('dossier_id, users.email')
          .group_by { |dossier_id, _| dossier_id }
          .to_h { |dossier_id, dossier_id_emails| [dossier_id, dossier_id_emails.map { |_, email| email }&.join(', ')] }
      end
    end

    Dossier
      .select(:id, :state, :archived) # the dossier object is needed in the view
      .find(dossiers_ids) # keeps dossiers_ids order and raise exception if one is missing
      .map do |dossier|
      DossierProjection.new(dossier, fields.map { |f| f[:id_value_h][dossier.id] })
    end
  end
end
