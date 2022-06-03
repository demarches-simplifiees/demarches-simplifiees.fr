# Display a widget for uploading, editing and deleting a file attachment
class Attachment::EditComponent < ApplicationComponent
  def initialize(form:, attached_file:, accept: nil, template: nil, user_can_destroy: false, direct_upload: true)
    @form = form
    @attached_file = attached_file
    @accept = accept
    @template = template
    @user_can_destroy = user_can_destroy
    @direct_upload = direct_upload
  end

  attr_reader :template, :form

  def self.text(form, file)
    new(form: form, attached_file: file, user_can_destroy: true)
  end

  def self.image(form, file, direct_upload = true)
    new(form: form,
      attached_file: file,
      accept: 'image/png, image/jpg, image/jpeg',
      user_can_destroy: true,
      direct_upload: direct_upload)
  end

  def user_can_destroy?
    @user_can_destroy
  end

  def attachment
    @attached_file.attachment
  end

  def attachment_path
    helpers.attachment_path attachment.id, { signed_id: attachment.blob.signed_id }
  end

  def attachment_id
    @attachment_id ||= attachment ? attachment.id : SecureRandom.uuid
  end

  def attachment_input_class
    "attachment-input-#{attachment_id}"
  end

  def persisted?
    attachment&.persisted?
  end

  def champ
    @form.object.is_a?(Champ) ? @form.object : nil
  end

  def file_field_options
    {
      class: "attachment-input #{attachment_input_class} #{'hidden' if persisted?}",
      accept: @accept,
      direct_upload: @direct_upload,
      id: champ&.input_id,
      aria: { describedby: champ&.describedby_id },
      data: { auto_attach_url: helpers.auto_attach_url(form, form.object) }
    }
  end

  def file_field_name
    @attached_file.name
  end

  def remove_button_options
    {
      role: 'button',
      class: 'button small danger',
      data: { turbo_method: :delete }
    }
  end

  def retry_button_options
    {
      type: 'button',
      class: 'button attachment-error-retry',
      data: { input_target: ".#{attachment_input_class}", action: 'autosave#onClickRetryButton' }
    }
  end

  def replace_button_options
    {
      type: 'button',
      class: 'button small',
      data: { toggle_target: ".#{attachment_input_class}" }
    }
  end
end
