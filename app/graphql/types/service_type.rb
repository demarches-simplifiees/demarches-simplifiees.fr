module Types
  class ServiceType < Types::BaseObject
    class TypeOrganisme < Types::BaseEnum
      Service.type_organismes.each do |symbol_name, string_name|
        value(string_name, I18n.t(symbol_name, scope: [:type_organisme]), value: symbol_name)
      end
    end

    global_id_field :id

    field :nom, String, null: false
    field :type_organisme, TypeOrganisme, null: false
    field :organisme, String, null: false
  end
end
