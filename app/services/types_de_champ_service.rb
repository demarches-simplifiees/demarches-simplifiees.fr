class TypesDeChampService
  include Rails.application.routes.url_helpers

  TOGGLES = {
    TypeDeChamp.type_champs.fetch(:siret)                 => :champ_siret?,
    TypeDeChamp.type_champs.fetch(:integer_number)        => :champ_integer_number?,
    TypeDeChamp.type_champs.fetch(:repetition)            => :champ_repetition?
  }

  def options
    types_de_champ = TypeDeChamp.type_de_champs_list_fr

    types_de_champ.select! do |tdc|
      toggle = TOGGLES[tdc.last]
      toggle.blank? || Flipflop.send(toggle)
    end

    types_de_champ
  end

  def initialize(procedure, private_type_de_champ = false)
    @procedure = procedure
    @private_type_de_champ = private_type_de_champ
  end

  def private?
    @private_type_de_champ
  end

  def active
    private? ? 'Annotations privées' : 'Champs'
  end

  def url
    private? ? admin_procedure_types_de_champ_private_path(@procedure) : admin_procedure_types_de_champ_path(@procedure)
  end

  def types_de_champ
    private? ? @procedure.types_de_champ_private_ordered.decorate : @procedure.types_de_champ_ordered.decorate
  end

  def new_type_de_champ
    TypeDeChamp.new(private: private?).decorate
  end

  def fields_for_var
    private? ? :types_de_champ_private : :types_de_champ
  end

  def move_up_url(ff)
    private? ? move_up_admin_procedure_types_de_champ_private_path(@procedure, ff.index) : move_up_admin_procedure_types_de_champ_path(@procedure, ff.index)
  end

  def move_down_url(ff)
    private? ? move_down_admin_procedure_types_de_champ_private_path(@procedure, ff.index) : move_down_admin_procedure_types_de_champ_path(@procedure, ff.index)
  end

  def delete_url(ff)
    private? ? admin_procedure_type_de_champ_private_path(@procedure, ff.object.id) : admin_procedure_type_de_champ_path(@procedure, ff.object.id)
  end

  def add_button_id
    private? ? :add_type_de_champ_private : :add_type_de_champ
  end

  def create_update_procedure_params(params)
    attributes = "#{fields_for_var}_attributes"
    params_with_ordered_champs = order_champs(params, attributes)

    parameters = params_with_ordered_champs
      .require(:procedure)
      .permit(attributes.to_s => [
        :libelle,
        :description,
        :order_place,
        :type_champ,
        :id,
        :mandatory,
        :piece_justificative_template,
        :quartiers_prioritaires,
        :cadastres,
        :parcelles_agricoles,
        drop_down_list_attributes: [:value, :id]
      ])

    parameters[attributes].each do |index, param|
      param[:private] = private?
      if param[:libelle].empty?
        parameters[attributes].delete(index.to_s)
      end

      if param['drop_down_list_attributes'] && param['drop_down_list_attributes']['value']
        param['drop_down_list_attributes']['value'] = clean_value(param['drop_down_list_attributes']['value'])
      end
    end

    parameters
  end

  private

  def order_champs(params, attributes)
    # It's OK to use an unsafe hash here because the params will then go through
    # require / permit methods in #create_update_procedure_params
    tdcas = params[:procedure][attributes].to_unsafe_hash.to_a
      .map { |_hash_index, tdca| tdca }

    tdcas
      .select { |tdca| !is_number?(tdca[:custom_order_place]) }
      .each { |tdca| tdca[:custom_order_place] = (tdca[:order_place].to_i + 1).to_s }

    changed_order_tdcas, ordered_tdcas = tdcas.partition { |tdca| tdca_order_changed?(tdca) }

    go_up_tdcas, go_down_tdcas = changed_order_tdcas
      .partition { |tdca| tdca[:custom_order_place].to_i < (tdca[:order_place].to_i + 1) }

    # needed to make the sort_by work properly
    tdcas = go_up_tdcas + ordered_tdcas + go_down_tdcas

    ordered_tdcas = tdcas
      .sort_by { |tdca| tdca[:custom_order_place].to_i }
      .each_with_index { |tdca, index| tdca[:order_place] = index.to_s }
      .each_with_index.reduce({}) { |acc, (tdca, hash_index)| acc[hash_index.to_s] = tdca; acc }

    params[:procedure][attributes] = ActionController::Parameters.new(ordered_tdcas)

    params
  end

  def is_number?(value)
    (value =~ /^[0-9]+$/) == 0
  end

  def tdca_order_changed?(tdca)
    (tdca[:order_place].to_i + 1) != tdca[:custom_order_place].to_i
  end

  def clean_value(value)
    value.split("\r\n").map(&:strip).join("\r\n")
  end
end
