class TypesDeChampEditor::ChampComponent < ApplicationComponent
  def initialize(type_de_champ:)
    @type_de_champ = type_de_champ
  end

  attr_reader :type_de_champ

  def procedure
    @type_de_champ.procedure
  end

  def can_be_mandatory?
    !type_de_champ.header_section? && !type_de_champ.explication? && !type_de_champ.private?
  end

  def type_de_champ_path
    admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id)
  end

  def move_up_type_de_champ_path
    move_up_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id)
  end

  def move_down_type_de_champ_path
    move_down_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id)
  end

  def li_options
    {
      id: dom_id(type_de_champ.stable_self, :types_de_champ_editor),
      class: type_de_champ.header_section? ? 'type-header-section' : '',
      data: { sortable_update_url: move_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id) }
    }
  end

  def form_options(class_name: '')
    {
      url: type_de_champ_path,
      multipart: true,
      html: { class: "form #{class_name}", data: { controller: 'submit' } }
    }
  end

  def types_of_type_de_champ
    filter_featured_tdc = -> (tdc) do
      feature_name = TypeDeChamp::FEATURE_FLAGS[tdc]
      feature_name.blank? || Flipper.enabled?(feature_name, helpers.current_user)
    end

    filter_tdc = -> (tdc) do
      case tdc
      when TypeDeChamp.type_champs.fetch(:number)
        has_legacy_number?
      when TypeDeChamp.type_champs.fetch(:cnaf)
        procedure.cnaf_enabled?
      when TypeDeChamp.type_champs.fetch(:dgfip)
        procedure.dgfip_enabled?
      when TypeDeChamp.type_champs.fetch(:pole_emploi)
        procedure.pole_emploi_enabled?
      when TypeDeChamp.type_champs.fetch(:mesri)
        procedure.mesri_enabled?
      else
        true
      end
    end

    TypeDeChamp.type_champs
      .keys
      .filter(&filter_tdc)
      .filter(&filter_featured_tdc)
      .map { |tdc| [t("activerecord.attributes.type_de_champ.type_champs.#{tdc}"), tdc] }
      .sort_by(&:first)
  end

  private

  def has_legacy_number?
    (procedure.types_de_champ + procedure.types_de_champ_private).any?(&:legacy_number?)
  end
end
