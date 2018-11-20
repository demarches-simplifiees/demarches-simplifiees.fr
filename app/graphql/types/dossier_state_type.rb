module Types
  class DossierStateType < Types::BaseEnum
    Dossier.states.each do |symbol_name, string_name|
      value(string_name,
        I18n.t(symbol_name, scope: [:activerecord, :attributes, :dossier, :state]),
        value: symbol_name)
    end
  end
end
