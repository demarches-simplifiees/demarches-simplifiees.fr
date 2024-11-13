# frozen_string_literal: true

class DossierProjectionService
  class DossierProjection < Struct.new(:dossier, :corrections, :columns) do
      def pending_correction?
        return false if corrections.blank?

        corrections.any? { _1[:resolved_at].nil? }
      end

      def resolved_corrections?
        return false if corrections.blank?

        corrections.all? { _1[:resolved_at].present? }
      end
    end
  end

  def self.for_tiers_translation(array)
    for_tiers, email, first_name, last_name = array
    if for_tiers == true
      "#{email} #{I18n.t('views.instructeurs.dossiers.acts_on_behalf')} #{first_name} #{last_name}"
    else
      email
    end
  end

  TABLE = 'table'
  COLUMN = 'column'
  STABLE_ID = 'stable_id'

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
  def self.project(dossiers_ids, columns)
    fields = columns.map do |c|
      if c.is_a?(Columns::ChampColumn)
        { TABLE => c.table, STABLE_ID => c.stable_id, original_column: c }
      else
        { TABLE => c.table, COLUMN => c.column }
      end
    end
    champ_value = champ_value_formatter(dossiers_ids, fields)

    dossier_corrections = { TABLE => 'dossier_corrections', COLUMN => 'resolved_at' }

    ([dossier_corrections] + fields)
      .each { |f| f[:id_value_h] = {} }
      .group_by { |f| f[TABLE] } # one query per table
      .each do |table, fields|
      case table
      when 'type_de_champ'
        Champ
          .where(
            stable_id: fields.map { |f| f[STABLE_ID] },
            dossier_id: dossiers_ids
          )
          .select(:dossier_id, :value, :stable_id, :type, :external_id, :data, :value_json) # we cannot pluck :value, as we need the champ.to_s method
          .group_by(&:stable_id) # the champs are redispatched to their respective fields
          .map do |stable_id, champs|
            fields
              .filter { |f| f[STABLE_ID] == stable_id }
              .each do |field|
                column = field[:original_column]
                field[:id_value_h] = champs.to_h { [_1.dossier_id, column.is_a?(Columns::JSONPathColumn) ? column.value(_1) : champ_value.(_1)] }
              end
          end
      when 'self'
        Dossier
          .where(id: dossiers_ids)
          .pluck(:id, *fields.map { |f| f[COLUMN].to_sym })
          .each do |id, *columns|
            fields.zip(columns).each do |field, value|
              # SVA must remain a date: in other column we compute remaining delay with it
              field[:id_value_h][id] = if value.respond_to?(:strftime)
                I18n.l(value.to_date)
              else
                value
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
          .includes(:individual)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, dossiers.for_tiers, users.email, individuals.prenom, individuals.nom')
          .to_h { |dossier_id, *array| [dossier_id, for_tiers_translation(array)] }
      when 'groupe_instructeur'
        fields[0][:id_value_h] = Dossier
          .joins(:groupe_instructeur)
          .where(id: dossiers_ids)
          .pluck('dossiers.id, groupe_instructeurs.label')
          .to_h
      when 'dossier_corrections'
        columns = fields.map { _1[COLUMN].to_sym }

        id_value_h = DossierCorrection.where(dossier_id: dossiers_ids)
          .pluck(:dossier_id, *columns)
          .group_by(&:first) # group corrections by dossier_id
          .transform_values do |values| # build each correction has an hash column => value
            values.map { Hash[columns.zip(_1[1..-1])] }
          end

        fields[0][:id_value_h] = id_value_h

      when 'dossier_labels'
        columns = fields.map { _1[COLUMN].to_sym }

        id_value_h =
          DossierLabel
            .includes(:label)
            .where(dossier_id: dossiers_ids)
            .pluck('dossier_id, labels.name, labels.color')
            .group_by { |dossier_id, _| dossier_id }

        fields[0][:id_value_h] = id_value_h.transform_values { |v| { value: v, type: :label } }

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
      when 'avis'
        # rubocop:disable Style/HashTransformValues
        fields[0][:id_value_h] = Avis
          .where(dossier_id: dossiers_ids)
          .pluck('dossier_id', 'question_answer')
          .group_by { |dossier_id, _| dossier_id }
          .to_h { |dossier_id, question_answer| [dossier_id, question_answer.map { |_, answer| answer }&.compact&.tally&.map { |k, v| I18n.t("helpers.label.question_answer_with_count.#{k}", count: v) }&.join(' / ')] }
        # rubocop:enable Style/HashTransformValues
      end
    end

    dossiers = Dossier.find(dossiers_ids)

    dossiers_ids.map do |dossier_id|
      DossierProjection.new(
        dossiers.find { _1.id == dossier_id },
        dossier_corrections[:id_value_h][dossier_id],
        fields.map { |f| f[:id_value_h][dossier_id] }
      )
    end
  end

  class << self
    private

    def champ_value_formatter(dossiers_ids, fields)
      stable_ids = fields.filter { _1[TABLE].in?(['type_de_champ']) }.map { _1[STABLE_ID] }
      revision_ids_by_dossier_ids = Dossier.where(id: dossiers_ids).pluck(:id, :revision_id).to_h
      stable_ids_and_types_de_champ_by_revision_ids = ProcedureRevisionTypeDeChamp.includes(:type_de_champ)
        .where(revision_id: revision_ids_by_dossier_ids.values.uniq, type_de_champ: { stable_id: stable_ids })
        .map { [_1.revision_id, _1.type_de_champ] }
        .group_by(&:first)
        .transform_values { _1.map { |_, type_de_champ| [type_de_champ.stable_id, type_de_champ] }.to_h }
      stable_ids_and_types_de_champ_by_dossier_ids = revision_ids_by_dossier_ids.transform_values { stable_ids_and_types_de_champ_by_revision_ids[_1] }.compact
      -> (champ) {
        type_de_champ = stable_ids_and_types_de_champ_by_dossier_ids
          .fetch(champ.dossier_id, {})[champ.stable_id]
        type_de_champ&.champ_value(champ)
      }
    end
  end
end
