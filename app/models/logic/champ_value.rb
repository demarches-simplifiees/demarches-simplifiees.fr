class Logic::ChampValue < Logic::Term
  MANAGED_TYPE_DE_CHAMP = TypeDeChamp.type_champs.slice(
    :yes_no,
    :checkbox,
    :integer_number,
    :decimal_number,
    :drop_down_list,
    :multiple_drop_down_list,
    :communes,
    :epci,
    :departements,
    :regions,
    :commune_de_polynesie,
    :code_postal_de_polynesie
  )

  CHAMP_VALUE_TYPE = {
    boolean: :boolean, # from yes_no or checkbox champ
    number: :number, # from integer or decimal number champ
    enum: :enum, # a choice from a dropdownlist
    commune_enum: :commune_enum,
    epci_enum: :epci_enum,
    departement_enum: :departement_enum,
    enums: :enums, # multiple choice from a dropdownlist (multipledropdownlist)
    empty: :empty,
    unmanaged: :unmanaged,
    commune_de_polynesie_enum: :commune_de_polynesie_enum,
    code_postal_de_polynesie_enum: :code_postal_de_polynesie_enum
  }

  attr_reader :stable_id

  def initialize(stable_id)
    @stable_id = stable_id
  end

  def sources
    [@stable_id]
  end

  def compute(champs)
    targeted_champ = champ(champs)

    return nil if targeted_champ.nil?
    return nil if !targeted_champ.visible?
    return nil if targeted_champ.blank? & !targeted_champ.drop_down_other?

    # on dépense 22ms ici, à cause du map, mais on doit pouvoir passer par un champ type
    case targeted_champ.type
    when "Champs::YesNoChamp",
      "Champs::CheckboxChamp"
      targeted_champ.true?
    when "Champs::IntegerNumberChamp", "Champs::DecimalNumberChamp"
      targeted_champ.for_api
    when "Champs::DropDownListChamp"
      targeted_champ.selected
    when "Champs::MultipleDropDownListChamp"
      targeted_champ.selected_options
    when "Champs::RegionChamp"
      targeted_champ.code
    when "Champs::DepartementChamp"
      {
        value: targeted_champ.code,
        code_region: targeted_champ.code_region
      }
    when "Champs::CommuneChamp", "Champs::EpciChamp"
      {
        code_departement: targeted_champ.code_departement,
        code_region: targeted_champ.code_region
      }
    when "Champs::CommuneDePolynesieChamp", "Champs::CodePostalDePolynesieChamp"
      {
        archipel: targeted_champ.archipel
      }
    end
  end

  def to_s(type_de_champs) = type_de_champ(type_de_champs)&.libelle # TODO: gerer le cas ou un tdc est supprimé

  def type(type_de_champs)
    case type_de_champ(type_de_champs)&.type_champ # TODO: gerer le cas ou un tdc est supprimé
    when MANAGED_TYPE_DE_CHAMP.fetch(:yes_no),
      MANAGED_TYPE_DE_CHAMP.fetch(:checkbox)
      CHAMP_VALUE_TYPE.fetch(:boolean)
    when MANAGED_TYPE_DE_CHAMP.fetch(:integer_number), MANAGED_TYPE_DE_CHAMP.fetch(:decimal_number)
      CHAMP_VALUE_TYPE.fetch(:number)
    when MANAGED_TYPE_DE_CHAMP.fetch(:drop_down_list),
      MANAGED_TYPE_DE_CHAMP.fetch(:regions)
      CHAMP_VALUE_TYPE.fetch(:enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:communes)
      CHAMP_VALUE_TYPE.fetch(:commune_enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:epci)
      CHAMP_VALUE_TYPE.fetch(:epci_enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:commune_de_polynesie)
      CHAMP_VALUE_TYPE.fetch(:commune_de_polynesie_enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:code_postal_de_polynesie)
      CHAMP_VALUE_TYPE.fetch(:code_postal_de_polynesie_enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:departements)
      CHAMP_VALUE_TYPE.fetch(:departement_enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:multiple_drop_down_list)
      CHAMP_VALUE_TYPE.fetch(:enums)
    else
      CHAMP_VALUE_TYPE.fetch(:unmanaged)
    end
  end

  def errors(type_de_champs)
    if !type_de_champs.map(&:stable_id).include?(stable_id)
      [{ type: :not_available }]
    else
      []
    end
  end

  def to_h
    {
      "term" => self.class.name,
      "stable_id" => @stable_id
    }
  end

  def self.from_h(h)
    self.new(h['stable_id'])
  end

  def ==(other)
    self.class == other.class && @stable_id == other.stable_id
  end

  def options(type_de_champs, operator_name = nil)
    tdc = type_de_champ(type_de_champs)

    if operator_name.in?([Logic::InRegionOperator.name, Logic::NotInRegionOperator.name]) || tdc.type_champ == MANAGED_TYPE_DE_CHAMP.fetch(:regions)
      APIGeoService.regions.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    elsif operator_name.in?([Logic::InDepartementOperator.name, Logic::NotInDepartementOperator.name]) || tdc.type_champ.in?([MANAGED_TYPE_DE_CHAMP.fetch(:communes), MANAGED_TYPE_DE_CHAMP.fetch(:epci), MANAGED_TYPE_DE_CHAMP.fetch(:departements)])
      APIGeoService.departements.map { ["#{_1[:code]} – #{_1[:name]}", _1[:code]] }
    elsif operator_name.in?([Logic::InArchipelOperator.name, Logic::NotInArchipelOperator.name]) || tdc.type_champ.in?([MANAGED_TYPE_DE_CHAMP.fetch(:commune_de_polynesie), MANAGED_TYPE_DE_CHAMP.fetch(:code_postal_de_polynesie)])
      APIGeo::API.archipels_de_polynesie.map { [_1, _1] }
    else
      tdc.drop_down_list_enabled_non_empty_options(other: true).map { _1.is_a?(Array) ? _1 : [_1, _1] }
    end
  end

  private

  def type_de_champ(type_de_champs)
    type_de_champs.find { |c| c.stable_id == stable_id }
  end

  def champ(champs)
    champs.find { |c| c.stable_id == stable_id }
  end
end
