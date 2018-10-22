class ProcedureSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attribute :libelle, key: :label

  attributes :id,
    :description,
    :organisation,
    :direction,
    :archived_at,
    :geographic_information,
    :total_dossier,
    :link,
    :state

  has_one :geographic_information, serializer: ModuleApiCartoSerializer
  has_many :types_de_champ, serializer: TypeDeChampSerializer
  has_many :types_de_champ_private, serializer: TypeDeChampSerializer
  has_many :types_de_piece_justificative, serializer: TypeDePieceJustificativeSerializer

  def link
    if object.path.present?
      if object.brouillon_avec_lien?
        commencer_test_url(procedure_path: object.path)
      else
        commencer_url(procedure_path: object.path)
      end
    end
  end

  def state
    object.aasm_state
  end

  def geographic_information
    object.module_api_carto
  end
end
