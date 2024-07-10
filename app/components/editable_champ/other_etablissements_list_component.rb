class EditableChamp::OtherEtablissementsListComponent < ApplicationComponent
  def initialize(other_etablissements:, input_id:)
    @other_etablissements = other_etablissements
    @input_id = input_id
  end
end
