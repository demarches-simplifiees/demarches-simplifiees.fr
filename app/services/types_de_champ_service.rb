class TypesDeChampService
  def self.create_update_procedure_params(params, private=false)
    attributes = (private ? 'types_de_champ_private_attributes' : 'types_de_champ_attributes')

    parameters = params
        .require(:procedure)
        .permit("#{attributes}" => [:libelle, :description, :order_place, :type_champ, :id, :mandatory, :type,
                                    drop_down_list_attributes: [:value, :id]])


    parameters[attributes].each do |param_first, param_second|
      if param_second[:libelle].empty?
        parameters[attributes].delete(param_first.to_s)
      end

      if param_second['drop_down_list_attributes'] && param_second['drop_down_list_attributes']['value']
        param_second['drop_down_list_attributes']['value'] = self.clean_value (param_second['drop_down_list_attributes']['value'])
      end
    end

    parameters
  end

  private

  def self.clean_value value
    value.split("\r\n").map{ |v| v.strip }.join("\r\n")
  end
end
