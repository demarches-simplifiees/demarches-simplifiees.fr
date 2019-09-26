module Types::Champs
  class DossierLinkChampType < Types::BaseObject
    implements Types::ChampType

    field :dossier, Types::DossierType, null: true

    def dossier
      if object.value.present?
        Loaders::Record.for(Dossier).load(object.value)
      end
    end
  end
end
