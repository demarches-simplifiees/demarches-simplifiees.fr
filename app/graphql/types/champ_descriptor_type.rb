module Types
  class ChampDescriptorType < Types::BaseObject
    class TypeDeChampType < Types::BaseEnum
      TypeDeChamp.type_champs.each do |symbol_name, string_name|
        value(string_name,
          I18n.t(symbol_name, scope: [:activerecord, :attributes, :type_de_champ, :type_champs]),
          value: symbol_name)
      end
    end

    global_id_field :id
    field :type, TypeDeChampType, "Type de la valeur du champ.", null: false, method: :type_champ
    field :label, String, "Libellé du champ.", null: false, method: :libelle
    field :description, String, "Description du champ.", null: true
    field :required, Boolean, "Est-ce que le champ est obligatoire ?", null: false, method: :mandatory?

    field :champ_descriptors, [Types::ChampDescriptorType], "Description des champs d’un bloc répétable.", null: true
    field :options, [String], "List des options d’un champ avec selection.", null: true

    def champ_descriptors
      if object.repetition?
        Loaders::Association.for(object.class, :types_de_champ).load(object)
      end
    end

    def options
      if object.drop_down_list?
        object.drop_down_list_options.reject(&:empty?)
      end
    end
  end
end
