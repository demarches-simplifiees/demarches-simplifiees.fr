# frozen_string_literal: true

class Columns::DossierLabelsColumn < Columns::DossierColumn
  def initialize(procedure_id:, options_for_select:)
    super(procedure_id:, table: 'dossier_labels', column: 'label_id', type: :enum, options_for_select:)
  end

  def value(dossier) = dossier.labels.map(&:name).join(' ')

  def sorted_ids(dossiers, order, **)
    dossiers
      .includes(:labels)
      .order("labels.name #{order}")
      .pluck(:id)
      .uniq
  end

  def filtered_ids_for_values(dossiers, values)
    return dossiers.ids unless values.any?(&:present?)

    dossiers
      .joins(:dossier_labels)
      .where(dossier_labels: { label_id: values })
      .ids
  end
end
