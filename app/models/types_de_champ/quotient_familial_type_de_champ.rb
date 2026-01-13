# frozen_string_literal: true

class TypesDeChamp::QuotientFamilialTypeDeChamp < TypesDeChamp::TypeDeChampBase
  def create_substitution_champ
    draft = @type_de_champ.revisions.first.procedure.draft_revision

    return if draft.children_of(@type_de_champ).any?

    draft.add_type_de_champ(
      {
        libelle: 'Justificatif de quotient familial',
        type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative),
        parent_stable_id: @type_de_champ.stable_id,
      }
    )
  end

  def champ_blank?(champ)
    return true if champ.recovered_qf_data? && champ.value_json['correct_qf_data'].blank?

    if champ.not_recovered_qf_data? || champ.incorrect_qf_data?
      dossier = champ.dossier
      substitution_tdc = dossier.revision.children_of(self).first
      substitution_champ = dossier.champs.find { |champ| champ.stable_id == substitution_tdc.stable_id }

      substitution_tdc.champ_blank?(substitution_champ)
    end
  end
end