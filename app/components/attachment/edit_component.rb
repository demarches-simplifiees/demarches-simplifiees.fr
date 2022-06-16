# Display a widget for uploading, editing and deleting a file attachment
class Attachment::EditComponent < ApplicationComponent
  def initialize(form:, attached_file:, template: nil, user_can_destroy: false, direct_upload: true, id: nil)
    @form = form
    @attached_file = attached_file
    @template = template
    @user_can_destroy = user_can_destroy
    @direct_upload = direct_upload
    @id = id
  end

  attr_reader :template, :form

  def allowed_extensions
    content_type_validator.options[:in]
      .flat_map { |content_type| MIME::Types[content_type].map(&:extensions) }
      .reject(&:blank?)
      .flatten
  end

  def max_file_size
    file_size_validator.options[:less_than]
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
      accept: content_type_validator.options[:in].join(', '),
      direct_upload: @direct_upload,
      id: input_id(@id),
      aria: { describedby: champ&.describedby_id },
      data: {
        auto_attach_url: helpers.auto_attach_url(form.object),
        max_file_size: max_file_size
      }
    }
  end

  def input_id(given_id)
    [given_id, champ&.input_id, file_field_name].reject(&:blank?).compact.first
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

  def file_size_validator
    @attached_file.record
      ._validators[file_field_name.to_sym]
      .find { |validator| validator.class == ActiveStorageValidations::SizeValidator }
  end

  def content_type_validator
    @attached_file.record
      ._validators[file_field_name.to_sym]
      .find { |validator| validator.class == ActiveStorageValidations::ContentTypeValidator }
  end
end
