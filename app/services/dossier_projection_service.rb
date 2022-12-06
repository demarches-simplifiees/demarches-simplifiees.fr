class DossierProjectionService
  class DossierProjection < Struct.new(:dossier_id, :state, :archived, :hidden_by_user_at, :hidden_by_administration_at, :batch_operation_id, :columns)
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
    state_field = { TABLE => 'self', COLUMN => 'state' }
    archived_field = { TABLE => 'self', COLUMN => 'archived' }
    batch_operation_field = { TABLE => 'self', COLUMN => 'batch_operation_id' }
    hidden_by_user_at_field = { TABLE => 'self', COLUMN => 'hidden_by_user_at' }
    hidden_by_administration_at_field = { TABLE => 'self', COLUMN => 'hidden_by_administration_at' }
    ([state_field, archived_field, hidden_by_user_at_field, hidden_by_administration_at_field, batch_operation_field] + fields) # the view needs state and archived dossier attributes
      .each { |f| f[:id_value_h] = {} }
      .group_by { |f| f[TABLE] } # one query per table
      .each do |table, fields|
      case table
      when 'type_de_champ', 'type_de_champ_private'
        Champ
          .includes(:type_de_champ)
          .where(
            types_de_champ: { stable_id: fields.map { |f| f[COLUMN] } },
            dossier_id: dossiers_ids
          )
          .select(:dossier_id, :value, :type_de_champ_id, :stable_id, :type, :external_id, :data) # we cannot pluck :value, as we need the champ.to_s method
          .group_by(&:stable_id) # the champs are redispatched to their respective fields
          .map do |stable_id, champs|
            field = fields.find { |f| f[COLUMN] == stable_id.to_s }
            field[:id_value_h] = champs.to_h { |c| [c.dossier_id, c.to_s] }
          end
      when 'self'
        Dossier
          .where(id: dossiers_ids)
          .pluck(:id, *fields.map { |f| f[COLUMN].to_sym })
          .each do |id, *columns|
            fields.zip(columns).each do |field, value|
              if [state_field, archived_field, hidden_by_user_at_field, hidden_by_administration_at_field, batch_operation_field].include?(field)
                field[:id_value_h][id] = value
              else
                field[:id_value_h][id] = value&.strftime('%d/%m/%Y') # other fields are datetime
              end
            end
          end
      when 'individual'
        Individual
          .where(dossier_id: dossiers_ids)
          .pluck(:dossier_id, *fields.map { |f| f[COLUMN].to_sym })
          .each { |id, *columns| fields.zip(columns).each { |field, value| field[:id_value_h][id] = value } }
      when 'etablissement'
        Etablissement
          .where(dossier_id: dossiers_ids)
          .pluck(:dossier_id, *fields.map { |f| f[COLUMN].to_sym })
          .each { |id, *columns| fields.zip(columns).each { |field, value| field[:id_value_h][id] = value } }
      when 'user'
        fields[0][:id_value_h] = Dossier # there is only one field available for user table
          .joins(:user)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, users.email')
          .to_h
      when 'groupe_instructeur'
        fields[0][:id_value_h] = Dossier
          .joins(:groupe_instructeur)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, groupe_instructeurs.label')
          .to_h
      when 'procedure'
        Dossier
          .joins(:procedure)
          .where(id: dossiers_ids)
          .pluck(:id, *fields.map { |f| f[COLUMN].to_sym })
          .each { |id, *columns| fields.zip(columns).each { |field, value| field[:id_value_h][id] = value } }
      when 'followers_instructeurs'
        # rubocop:disable Style/HashTransformValues
        fields[0][:id_value_h] = Follow
          .active
          .joins(instructeur: :user)
          .where(dossier_id: dossiers_ids)
          .pluck('dossier_id, users.email')
          .group_by { |dossier_id, _| dossier_id }
          .to_h { |dossier_id, dossier_id_emails| [dossier_id, dossier_id_emails.sort.map { |_, email| email }&.join(', ')] }
        # rubocop:enable Style/HashTransformValues
      end
    end

    dossiers_ids.map do |dossier_id|
      DossierProjection.new(
        dossier_id,
        state_field[:id_value_h][dossier_id],
        archived_field[:id_value_h][dossier_id],
        hidden_by_user_at_field[:id_value_h][dossier_id],
        hidden_by_administration_at_field[:id_value_h][dossier_id],
        batch_operation_field[:id_value_h][dossier_id],
        fields.map { |f| f[:id_value_h][dossier_id] }
      )
    end
  end
end
