class EditableChamp::EditableChampComponent < ApplicationComponent
  include Dsfr::InputErrorable

  def initialize(form:, champ:, seen_at: nil)
    @form, @champ, @seen_at = form, champ, seen_at
    @attribute = :value
  end

  private

  def has_label?(champ)
    types_without_label = [
      TypeDeChamp.type_champs.fetch(:header_section),
      TypeDeChamp.type_champs.fetch(:explication),
      TypeDeChamp.type_champs.fetch(:repetition)
    ]
    !types_without_label.include?(@champ.type_champ)
  end

  def component_class
    "EditableChamp::#{@champ.type_champ.camelcase}Component".constantize
  end

  def select_group
    [
      'departements',
      'drop_down_list',
      'epci',
      'pays',
      'regions'
    ]
  end

  def input_group
    [
      'annuaire_education',
      'date',
      'datetime',
      'decimal_number',
      'dgfip',
      'dossier_link',
      'email',
      'iban',
      'integer_number',
      'mesri',
      'number',
      'phone',
      'piece_justificative',
      'pole_emploi',
      'rna',
      'siret',
      'text',
      'textarea',
      'titre_identite'
    ]
  end

  def radio_group
    [
      'boolean',
      'yes_no'
    ]
  end

  def html_options
    {
      class: class_names(
        {
          'editable-champ': true,
          "editable-champ-#{@champ.type_champ}": true,
          "hidden": !@champ.visible?,
          "fr-input-group": input_group.include?(@champ.type_champ),
          "fr-select-group": select_group.include?(@champ.type_champ),
          "fr-radio-group": radio_group.include?(@champ.type_champ),
          "fr-fieldset": @champ.legend_label?
        }.merge(input_group_error_class_names)
      ),
      id: @champ.input_group_id,
      data: { controller: stimulus_controller, **data_dependent_conditions, **stimulus_values }
    }
  end

  def stimulus_values
    if @champ.fetch_external_data_pending?
      { turbo_poll_url_value: }
    else
      {}
    end
  end

  def turbo_poll_url_value
    if @champ.private?
      annotation_instructeur_dossier_path(@champ.dossier.procedure, @champ.dossier, @champ)
    else
      champ_dossier_path(@champ.dossier, @champ)
    end
  end

  def stimulus_controller
    if autosave_enabled?
      # This is an editable champ. Lets find what controllers it might need.
      controllers = ['autosave']

      if @champ.fetch_external_data_pending?
        controllers << 'turbo-poll'
      end

      controllers.join(' ')
    end
  end

  def data_dependent_conditions
    if @champ.dependent_conditions?
      { "dependent-conditions": "true" }
    else
      {}
    end
  end

  def autosave_enabled?
    !@champ.carte? && !@champ.block? && @champ.fillable?
  end
end
