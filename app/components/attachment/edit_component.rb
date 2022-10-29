# Display a widget for uploading, editing and deleting a file attachment
class Attachment::EditComponent < ApplicationComponent
  attr_reader :template, :form, :attachment

  delegate :persisted?, to: :attachment, allow_nil: true

  def initialize(form:, attached_file:, user_can_destroy: false, direct_upload: true, id: nil, index: 0, **kwargs)
    @form = form
    @attached_file = attached_file

    @attachment = if kwargs.key?(:attachment)
      kwargs[:attachment]
    elsif attached_file.respond_to?(:attachment)
      attached_file.attachment
    else
      fail ArgumentError, "You must pass an `attachment` kwarg when not using as single attachment like in #{attached_file.name}. Set it to nil for a new attachment."
    end

    @user_can_destroy = user_can_destroy
    @direct_upload = direct_upload
    @id = id
    @index = index
  end

  def max_file_size
    file_size_validator.options[:less_than]
  end

  def user_can_destroy?
    @user_can_destroy
  end

  def attachment_path
    helpers.attachment_path attachment.id, { signed_id: attachment.blob.signed_id }
  end

  def attachment_id
    @attachment_id ||= (attachment&.id || SecureRandom.uuid)
  end

  def attachment_input_class
    "attachment-input-#{attachment_id}"
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
        auto_attach_url:
      }.merge(has_file_size_validator? ? { max_file_size: } : {})
    }.merge(has_content_type_validator? ? { accept: accept_content_type } : {})
  end

  def auto_attach_url
    helpers.auto_attach_url(form.object)
  end

  def input_id(given_id)
    return given_id if given_id.present?

    if champ.present?
      # Single or first attachment input must match label "for" attribute. Others must remain unique.
      return champ.input_id if @index.zero?
      return "#{champ.input_id}_#{attachment_id}"
    end

    file_field_name
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

  def accept_content_type
    list = content_type_validator.options[:in]
    if list.include?("application/octet-stream")
      list.push(".acidcsa")
    end
    list.join(', ')
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
