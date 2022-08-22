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
    track_issue_with_missing_validators if missing_validators?
    {
      class: "attachment-input #{attachment_input_class} #{'hidden' if persisted?}",
      direct_upload: @direct_upload,
      id: input_id(@id),
      aria: { describedby: champ&.describedby_id },
      data: {
        auto_attach_url: helpers.auto_attach_url(form.object)
      }.merge(has_file_size_validator? ? { max_file_size: max_file_size } : {})
    }.merge(has_content_type_validator? ? { accept: content_type_validator.options[:in].join(', ') } : {})
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

  def has_content_type_validator?
    !content_type_validator.nil?
  end

  def has_file_size_validator?
    !file_size_validator.nil?
  end

  def missing_validators?
    return true if !has_file_size_validator?
    return true if !has_content_type_validator?
    return false
  end

  def track_issue_with_missing_validators
    Sentry.capture_message(
      "Strange case of missing validator",
      extra: {
        champ: champ,
        file_field_name: file_field_name,
        attachment_id: attachment_id
      }
    )
  end
end
