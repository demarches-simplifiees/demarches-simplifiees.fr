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
      substitution_type_de_champ(champ).champ_blank?(substitution_champ(champ))
    end
  end

  def substitution_type_de_champ(champ)
    dossier = champ.dossier
    dossier.revision.children_of(self).first
  end

  def substitution_champ(champ)
    dossier = champ.dossier
    dossier.champs.find { |champ| champ.stable_id == substitution_type_de_champ(champ).stable_id }
  end
end