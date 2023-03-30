# Display a form for destroying a repetition row via a button, but since it might already be nested within a form
# put this component before the actual form containing the editable champs
class EditableChamp::DeleteFormRepetitionRowComponent < ApplicationComponent
  def self.form_id
    ActionView::RecordIdentifier.dom_id(Champs::RepetitionChamp.new, :delete)
  end

  def call
    form_tag('/champs/repetition/:id', method: :delete, data: { 'turbo-method': :delete, turbo: true }, id: self.class.form_id) {}
  end
end
