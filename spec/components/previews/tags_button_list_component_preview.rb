# frozen_string_literal: true

class TagsButtonListComponentPreview < ViewComponent::Preview
  include TagsSubstitutionConcern

  def default
    render(TagsButtonListComponent.new(tags:
      {
        individual: TagsSubstitutionConcern::INDIVIDUAL_TAGS,
        etablissement: TagsSubstitutionConcern::ENTREPRISE_TAGS,
        dossier: TagsSubstitutionConcern::DOSSIER_TAGS,
        champ_public: [
          {
            id: 'tdc12',
            libelle: 'Votre avis',
            description: 'Détaillez votre avis',
          },
          {
            id: 'tdc13',
            libelle: 'Votre avis très ' + 'long ' * 12,
            description: 'Ce libellé a été tronqué',
            maybe_null: true,
          }
        ],

        champ_private: [
          {
            id: 'tdc22',
            libelle: 'Montant accordé',
          }
        ],
      }))
  end
end
