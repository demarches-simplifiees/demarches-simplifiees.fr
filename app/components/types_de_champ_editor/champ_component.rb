class TypesDeChampEditor::ChampComponent < ApplicationComponent
  def initialize(coordinate:, focused: false)
    @coordinate = coordinate
    @focused = focused
  end

  private

  attr_reader :coordinate
  delegate :type_de_champ, :revision, :procedure, to: :coordinate

  def can_be_mandatory?
    type_de_champ.public? && !type_de_champ.non_fillable?
  end

  def type_de_champ_path
    admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id)
  end

  def html_options
    {
      id: dom_id(coordinate, :type_de_champ_editor),
      class: class_names('type-header-section': type_de_champ.header_section?,
        first: coordinate.first?,
        last: coordinate.last?),
      data: {
        controller: 'type-de-champ-editor',
        type_de_champ_editor_move_url_value: move_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id),
        type_de_champ_editor_move_up_url_value: move_up_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id),
        type_de_champ_editor_move_down_url_value: move_down_admin_procedure_type_de_champ_path(procedure, type_de_champ.stable_id),
        type_de_champ_editor_type_de_champ_stable_id_value: type_de_champ.stable_id
      }
    }
  end

  def form_options
    {
      url: type_de_champ_path,
      multipart: true,
      html: { id: nil, class: 'form width-100' }
    }
  end

  def move_button_options(direction)
    {
      type: 'button',
      data: { action: 'type-de-champ-editor#onMoveButtonClick', type_de_champ_editor_direction_param: direction },
      title: direction == :up ? 'Déplacer le champ vers le haut' : 'Déplacer le champ vers le bas'
    }
  end

  def input_autofocus
    @focused ? { controller: 'autofocus' } : nil
  end

  def types_of_type_de_champ
    TypeDeChamp.type_champs
      .keys
      .filter(&method(:filter_type_champ))
      .filter(&method(:filter_featured_type_champ))
      .filter(&method(:filter_block_type_champ))
      .map { |type_champ| [t("activerecord.attributes.type_de_champ.type_champs.#{type_champ}"), type_champ] }
      .sort_by(&:first)
  end

  def piece_justificative_options(form)
    {
      form: form,
      attached_file: type_de_champ.piece_justificative_template,
      user_can_destroy: true,
      id: dom_id(type_de_champ, :piece_justificative_template)
    }
  end

  EXCLUDE_FROM_BLOCK = [
    TypeDeChamp.type_champs.fetch(:carte),
    TypeDeChamp.type_champs.fetch(:dossier_link),
    TypeDeChamp.type_champs.fetch(:repetition),
    TypeDeChamp.type_champs.fetch(:siret)
  ]

  def filter_block_type_champ(type_champ)
    !coordinate.child? || !EXCLUDE_FROM_BLOCK.include?(type_champ)
  end

  def filter_featured_type_champ(type_champ)
    feature_name = TypeDeChamp::FEATURE_FLAGS[type_champ]
    feature_name.blank? || Flipper.enabled?(feature_name, helpers.current_user)
  end

  def filter_type_champ(type_champ)
    case type_champ
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

  def has_legacy_number?
    revision.types_de_champ.any?(&:legacy_number?)
  end
end
