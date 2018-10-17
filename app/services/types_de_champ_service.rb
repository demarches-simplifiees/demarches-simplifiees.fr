class TypesDeChampService
  def self.create_update_procedure_params(params, private = false)
    attributes = (private ? 'types_de_champ_private_attributes' : 'types_de_champ_attributes')

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
        drop_down_list_attributes: [:value, :id]
      ])

    parameters[attributes].each do |index, param|
      param[:private] = private
      if param[:libelle].empty?
        parameters[attributes].delete(index.to_s)
      end

      if param['drop_down_list_attributes'] && param['drop_down_list_attributes']['value']
        param['drop_down_list_attributes']['value'] = self.clean_value (param['drop_down_list_attributes']['value'])
      end
    end

    parameters
  end

  private

  def self.order_champs(params, attributes)
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

  def self.is_number?(value)
    (value =~ /^[0-9]+$/) == 0
  end

  def self.tdca_order_changed?(tdca)
    (tdca[:order_place].to_i + 1) != tdca[:custom_order_place].to_i
  end

  def self.clean_value(value)
    value.split("\r\n").map(&:strip).join("\r\n")
  end
end
