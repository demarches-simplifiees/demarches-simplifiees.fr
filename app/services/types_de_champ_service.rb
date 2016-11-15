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
    end

    parameters
  end
end