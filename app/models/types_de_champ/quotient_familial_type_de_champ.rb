# frozen_string_literal: true

class TypesDeChamp::QuotientFamilialTypeDeChamp < TypesDeChamp::TypeDeChampBase
  include Logic

  def create_substitution_champ
    draft = @type_de_champ.revisions.first.procedure.draft_revision

    return if draft.children_of(@type_de_champ).any?

    draft.add_type_de_champ(
      {
        libelle: 'Justificatif de quotient familial',
        type_champ: TypeDeChamp.type_champs.fetch(:piece_justificative),
        parent_stable_id: @type_de_champ.stable_id,
        condition: ds_not_eq(champ_value(@type_de_champ.stable_id), constant('correct')),
      }
    )
  end
end