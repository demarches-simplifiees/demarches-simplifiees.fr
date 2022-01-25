class Revisions::NoEmptyDropDownValidator < ActiveModel::EachValidator
  def validate_each(procedure, attribute, revision)
    return if revision.nil?

    tdcs = revision.types_de_champ + revision.types_de_champ_private
    drop_downs = tdcs.filter(&:drop_down_list?)
    drop_downs.each do |drop_down|
      validate_drop_down_not_empty(procedure, attribute, drop_down)
    end
  end

  private

  def validate_drop_down_not_empty(procedure, attribute, drop_down)
    if drop_down.drop_down_list_enabled_non_empty_options.empty?
      procedure.errors.add(
        attribute,
        procedure.errors.generate_message(attribute, :empty_drop_down, { value: drop_down.libelle })
      )
    end
  end
end
