# frozen_string_literal: true

class TypesDeChampEditor::ConditionsComponentPreview < ViewComponent::Preview
  include Logic

  def with_empty_condition
    tdc = TypeDeChamp.create(type_champ: :text, condition: empty_operator(empty, empty), libelle: 't')
    upper_tdcs = []

    render TypesDeChampEditor::ConditionsComponent.new(
      tdc: tdc, upper_tdcs: upper_tdcs, procedure_id: '1'
    )
  end

  def with_conditions
    surface = TypeDeChamp.create(type_champ: :integer_number, libelle: 'surface')
    appartement = TypeDeChamp.create(type_champ: :yes_no, libelle: 'appartement')
    type_appartement = TypeDeChamp.create(type_champ: :drop_down_list, libelle: 'type', drop_down_options: ["T1", "T2", "T3"])
    upper_tdcs = [surface, appartement, type_appartement]

    condition = ds_and([
      greater_than_eq(champ_value(surface.stable_id), constant(50)),
      ds_eq(champ_value(appartement.stable_id), constant(true)),
      ds_eq(champ_value(type_appartement.stable_id), constant('T2')),
    ])
    tdc = TypeDeChamp.create(type_champ: :integer_number, condition: condition, libelle: 'nb de piece')

    render TypesDeChampEditor::ConditionsComponent.new(
      tdc: tdc, upper_tdcs: upper_tdcs, procedure_id: '1'
    )
  end

  def with_errors
    surface = TypeDeChamp.create(type_champ: :integer_number, libelle: 'surface')
    address = TypeDeChamp.create(type_champ: :address, libelle: 'adresse')
    yes_non = TypeDeChamp.create(type_champ: :yes_no, libelle: 'oui/non')

    upper_tdcs = [address, yes_non]

    condition = ds_and([
      ds_eq(champ_value(address.stable_id), empty),
      greater_than_eq(champ_value(surface.stable_id), constant(50)),
      ds_eq(champ_value(yes_non.stable_id), constant(5)),
    ])

    tdc = TypeDeChamp.create(type_champ: :integer_number, condition: condition, libelle: 'nb de piece')

    render TypesDeChampEditor::ConditionsComponent.new(
      tdc: tdc, upper_tdcs: upper_tdcs, procedure_id: '1'
    )
  end
end
