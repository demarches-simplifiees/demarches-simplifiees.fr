# Display a form for destroying a file attachment via a button, but since it might already be nested within a form
# put this component before the actual form containing the editcomponent
class Attachment::DeleteFormComponent < ApplicationComponent
  def call
    form_tag('/attachments/:id', method: :delete, data: { 'turbo-method': :delete, turbo: true }, id: dom_id(ActiveStorage::Attachment.new, :delete)) {}
  end
end
