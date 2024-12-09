# frozen_string_literal: true

module ChampRevisionConcern
  extend ActiveSupport::Concern

  protected

  def is_same_type_as_revision?
    is_type?(type_de_champ.type_champ)
  end

  def in_dossier_revision?
    dossier.stable_id_in_revision?(stable_id)
  end

  def in_discarded_row?
    if child?
      repetition_type_de_champ = dossier.revision.parent_of(type_de_champ)
      row_ids = dossier.repetition_row_ids(repetition_type_de_champ)
      !row_id.in?(row_ids)
    end
  end
end
