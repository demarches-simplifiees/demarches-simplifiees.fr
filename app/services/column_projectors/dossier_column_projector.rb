# frozen_string_literal: true

class ColumnProjectors::DossierColumnProjector
  def self.project(all_columns, dossiers)
    dossier_ids = dossiers.map(&:id)

    columns_by_table = all_columns.group_by(&:table)

    columns_by_table.flat_map do |table, columns|
      case table
      when 'user'
        # there is only one column available for user table
        column = columns.first

        Dossier
          .joins(:user)
          .includes(:individual)
          .where(id: dossier_ids)
          .pluck('dossiers.id, dossiers.for_tiers, users.email, individuals.prenom, individuals.nom')
          .map { |dossier_id, *array| { dossier_id => { column.id => for_tiers_translation(array) } } }
      when 'individual'
        Individual
          .where(dossier_id: dossier_ids)
          .pluck(:dossier_id, *columns.map(&:column))
          .flat_map do |dossier_id, *values|
            columns.zip(values).map { |column, value| { dossier_id => { column.id => value } } }
          end
      when 'etablissement'
        Etablissement
          .where(dossier_id: dossier_ids)
          .pluck(:dossier_id, *columns.map(&:column))
          .flat_map do |dossier_id, *values|
            columns.zip(values).map { |column, value| { dossier_id => { column.id => value } } }
          end
      when 'self'
        dossiers.flat_map do |dossier|
          columns.map do |column|
            value = column.value(dossier)
            # SVA must remain a date: in other column we compute remaining delay with it
            if value.respond_to?(:strftime) && column.column != 'sva_svr_decision_on'
              { dossier.id => { column.id => I18n.l(value.to_date) } }
            else
              { dossier.id => { column.id => value } }
            end
          end
        end
      when 'groupe_instructeur'
        # there is only one column available for groupe instructeur
        column = columns.first

        Dossier
          .joins(:groupe_instructeur)
          .where(id: dossier_ids)
          .pluck('dossiers.id, groupe_instructeurs.label')
          .map { |dossier_id, label| { dossier_id => { column.id => label } } }
      when 'dossier_labels'
        # there is only one column available for dossier_labels
        column = columns.first

        DossierLabel
          .includes(:label)
          .where(dossier_id: dossier_ids)
          .pluck('dossier_id, labels.name, labels.color')
          .group_by { |dossier_id, _| dossier_id }
          .map do |dossier_id, labels|
            { dossier_id => { column.id => { value: labels, type: :label } } }
          end
      when 'followers_instructeurs'
        # there is only one column available for followers_instructeurs
        column = columns.first

        Follow
          .active
          .joins(instructeur: :user)
          .where(dossier_id: dossier_ids)
          .pluck('dossier_id, users.email')
          .group_by { |dossier_id, _| dossier_id }
          .map do |dossier_id, dossier_id_emails|
            { dossier_id => { column.id => dossier_id_emails.sort.map { |_, email| email }&.join(', ') } }
          end
      when 'avis'
        # there is only one column available for avis
        column = columns.first

        Avis
          .where(dossier_id: dossier_ids)
          .pluck('dossier_id', 'question_answer')
          .group_by { |dossier_id, _| dossier_id }
          .map do |dossier_id, question_answer|
            value = question_answer.map { |_, answer| answer }&.compact&.tally
              &.map { |k, v| I18n.t("helpers.label.question_answer_with_count.#{k}", count: v) }
              &.join(' / ')

            { dossier_id => { column.id => value } }
          end
      end
    end.reduce(&:deep_merge)
  end

  private

  def self.for_tiers_translation(array)
    for_tiers, email, first_name, last_name = array
    if for_tiers == true
      "#{email} #{I18n.t('views.instructeurs.dossiers.acts_on_behalf')} #{first_name} #{last_name}"
    else
      email
    end
  end
end
