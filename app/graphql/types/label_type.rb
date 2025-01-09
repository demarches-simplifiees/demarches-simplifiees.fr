# frozen_string_literal: true

class Types::LabelType < Types::BaseObject
  class Types::LabelColorEnum < Types::BaseEnum
    Label.colors.each_key do |color|
      value color, value: color
    end

    description "Couleurs disponibles pour les labels"
  end

  global_id_field :id
  field :name, String, null: false
  field :color, Types::LabelColorEnum, null: false, description: "Couleur du label"

  def self.authorized?(object, context)
    context.authorized_demarche?(object.procedure)
  end
end
