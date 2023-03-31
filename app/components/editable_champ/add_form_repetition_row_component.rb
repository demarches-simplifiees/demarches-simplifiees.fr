# Display a form for adding a repetition row via a button, but since it might already nested within a form
# put this component before the actual form containing the editable champs
class EditableChamp::AddFormRepetitionRowComponent < ApplicationComponent
  def self.form_id
    ActionView::RecordIdentifier.dom_id(Champs::RepetitionChamp.new, :create)
  end

  def call
    form_tag('/champs/repetition/:id', method: :post, data: { 'turbo-method': :post, turbo: true }, id: self.class.form_id) {}
  end
end
