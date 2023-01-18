module Types::Champs::Descriptor
  class PieceJustificativeChampDescriptorType < Types::BaseObject
    implements Types::ChampDescriptorType

    field :file_template, Types::File, "Modèle de la pièce justificative.", null: true, extensions: [
      { Extensions::Attachment => { attachment: :piece_justificative_template, root: :type_de_champ } }
    ]
  end
end
