class EditableChamp::ReferentielDePolynesieComponent < EditableChamp::ComboSearchComponent
  def dsfr_input_classname
    'fr-input'
  end

  def react_input_opts
    opts = input_opts(id: @champ.input_id, required: @champ.required?, aria: { describedby: @champ.describedby_id }, scopeExtra: @champ.table_id)
    opts[:className] = "#{opts.delete(:class)} fr-mt-1w"

    opts
  end
end
