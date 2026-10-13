# frozen_string_literal: true

class Columns::AvisColumn < Columns::DossierColumn
  def initialize(procedure_id:)
    super(procedure_id:, table: 'avis', column: 'question_answer', filterable: false)
  end

  def sorted_ids(dossiers, order, **)
    dossiers
      .includes(:avis)
      .order("avis.question_answer #{order}")
      .pluck(:id)
      .uniq
  end
end
