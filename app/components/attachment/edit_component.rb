# Display a widget for uploading, editing and deleting a file attachment
class Attachment::EditComponent < ApplicationComponent
  attr_reader :champ
  attr_reader :attachment
  attr_reader :user_can_download
  alias user_can_download? user_can_download
  attr_reader :user_can_destroy
  alias user_can_destroy? user_can_destroy
  attr_reader :as_multiple
  alias as_multiple? as_multiple

  EXTENSIONS_ORDER = ['jpeg', 'png', 'pdf', 'zip'].freeze

  def initialize(champ: nil, auto_attach_url: nil, field_name: nil, attached_file:, direct_upload: true, index: 0, as_multiple: false, user_can_download: false, user_can_destroy: true, **kwargs)
    @as_multiple = as_multiple
    @attached_file = attached_file
    @auto_attach_url = auto_attach_url
    @champ = champ
    @direct_upload = direct_upload
    @index = index
    @user_can_download = user_can_download
    @user_can_destroy = user_can_destroy

    # attachment passed by kwarg because we don't want a default (nil) value.
    @attachment = if kwargs.key?(:attachment)
      kwargs.delete(:attachment)
    elsif attached_file.respond_to?(:attachment)
      attached_file.attachment
    else
      fail ArgumentError, "You must pass an `attachment` kwarg when not using as single attachment like in #{attached_file.name}. Set it to nil for a new attachment."
    end

    verify_initialization!(kwargs)
  end

  def first?
    @index.zero?
  end

  def max_file_size
    return if file_size_validator.nil?

    file_size_validator.options[:less_than]
  end

  def attachment_id
    @attachment_id ||= (attachment&.id || SecureRandom.uuid)
  end

  def attachment_path(**args)
    helpers.attachment_path attachment.id, args.merge(signed_id: attachment.blob.signed_id)
  end

  def destroy_attachment_path
    attachment_path(champ_id: champ&.id)
  end

  def attachment_input_class
    "attachment-input-#{attachment_id}"
  end

  def file_field_options
    track_issue_with_missing_validators if missing_validators?
    {
      class: "fr-upload attachment-input #{attachment_input_class} #{persisted? ? 'hidden' : ''}",
      direct_upload: @direct_upload,
      id: input_id,
      aria: { describedby: champ&.describedby_id },
      data: {
        auto_attach_url:
      }.merge(has_file_size_validator? ? { max_file_size: } : {})
    }.merge(has_content_type_validator? ? { accept: accept_content_type } : {})
  end

  def in_progress?
    return false if attachment.nil?
    return true if attachment.virus_scanner.pending?
    return true if attachment.watermark_pending?

    false
  end

  def poll_controller_options
    {
      controller: 'turbo-poll',
      turbo_poll_url_value: poll_url
    }
  end

  def poll_url
    if champ.present?
      auto_attach_url
    else
      attachment_path(user_can_edit: true, user_can_download: @user_can_download, auto_attach_url: @auto_attach_url)
    end
  end

  def field_name
    helpers.field_name(ActiveModel::Naming.param_key(@attached_file.record), attribute_name)
  end

  def attribute_name
    @attached_file.name
  end

  def remove_button_options
    {
      role: 'button',
      data: { turbo: "true", turbo_method: :delete }
    }
  end

  def retry_button_options
    {
      type: 'button',
      class: 'fr-btn fr-btn--sm fr-btn--tertiary fr-mt-1w fr-icon-refresh-line fr-btn--icon-left attachment-error-retry',
      data: { input_target: ".#{attachment_input_class}", action: 'autosave#onClickRetryButton' }
    }
  end

  def persisted?
    !!attachment&.persisted?
  end

  def downloadable?
    return false unless user_can_download?
    return false if attachment.virus_scanner_error?
    return false if attachment.watermark_pending?

    true
  end

  def error?
    attachment.virus_scanner_error?
  end

  def error_message
    case
    when attachment.virus_scanner.infected?
      t(".errors.virus_infected")
    when attachment.virus_scanner.corrupt?
      t(".errors.corrupted_file")
    end
  end

  private

  def input_id
    if champ.present?
      # Single or first attachment input must match label "for" attribute. Others must remain unique.
      return champ.input_id if @index.zero?
      return "#{champ.input_id}_#{attachment_id}"
    end

    helpers.field_id(@attached_file.record, attribute_name)
  end

  def auto_attach_url
    return @auto_attach_url if @auto_attach_url.present?

    return helpers.auto_attach_url(@champ) if @champ.present?

    nil
  end

  def file_size_validator
    @attached_file.record
      ._validators[attribute_name.to_sym]
      .find { |validator| validator.class == ActiveStorageValidations::SizeValidator }
  end

  def content_type_validator
    @attached_file.record
      ._validators[attribute_name.to_sym]
      .find { |validator| validator.class == ActiveStorageValidations::ContentTypeValidator }
  end

  def accept_content_type
    list = content_type_validator.options[:in].dup
    list << ".acidcsa" if list.include?("application/octet-stream")
    list.join(', ')
  end

  def allowed_formats
    return nil unless champ&.titre_identite?

    @allowed_formats ||= begin
                           content_type_validator.options[:in].filter_map do |content_type|
                             MiniMime.lookup_by_content_type(content_type)&.extension
                           end.uniq.sort_by { EXTENSIONS_ORDER.index(_1) || 999 }
                         end
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

  def verify_initialization!(kwargs)
    fail ArgumentError, "Unknown kwarg #{kwargs.keys.join(', ')}" unless kwargs.empty?
  end

  def track_issue_with_missing_validators
    Sentry.capture_message(
      "Strange case of missing validator",
      extra: {
        champ: champ,
        field_name: field_name,
        attachment_id: attachment_id
      }
    )
  end
end
