# Display a widget for uploading, editing and deleting a file attachment
class Attachment::EditComponent < ApplicationComponent
  attr_reader :champ
  attr_reader :attachment
  attr_reader :attachments
  attr_reader :user_can_destroy
  alias user_can_destroy? user_can_destroy
  attr_reader :as_multiple
  alias as_multiple? as_multiple

  EXTENSIONS_ORDER = ['jpeg', 'png', 'pdf', 'zip'].freeze

  def initialize(champ: nil, auto_attach_url: nil, attached_file:, direct_upload: true, index: 0, as_multiple: false, view_as: :link, user_can_destroy: true, user_can_replace: false, attachments: [], **kwargs)
    @champ = champ
    @attached_file = attached_file
    @direct_upload = direct_upload
    @index = index
    @view_as = view_as
    @user_can_destroy = user_can_destroy
    @user_can_replace = user_can_replace
    @as_multiple = as_multiple
    @auto_attach_url = auto_attach_url
    # Adaptation pour la gestion des pièces jointes multiples
    @attachments = attachments.presence || (kwargs.key?(:attachment) ? [kwargs.delete(:attachment)] : [])
    @attachments << attached_file.attachment if attached_file.respond_to?(:attachment) && @attachments.empty?
    @attachments.compact!

    # Utilisation du premier attachement comme référence pour la rétrocompatibilité
    @attachment = @attachments.first

    # When parent form has nested attributes, pass the form builder object_name
    # to correctly infer the input attribute name.
    @form_object_name = kwargs.delete(:form_object_name)

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
    attachment_path(champ_id: champ&.public_id)
  end

  def attachment_input_class
    "attachment-input-#{attachment_id}"
  end

  def file_field_options
    track_issue_with_missing_validators if missing_validators?
    options = {
      class: class_names("fr-upload attachment-input": true, "#{attachment_input_class}": true, "hidden": persisted?),
      direct_upload: @direct_upload,
      id: input_id,
      aria: { describedby: champ&.describedby_id },
      data: {
        auto_attach_url:,
        turbo_force: :server
      }.merge(has_file_size_validator? ? { max_file_size: max_file_size } : {})
    }

    options.merge!(has_content_type_validator? ? { accept: accept_content_type } : {})
    options[:multiple] = true if as_multiple?

    options
  end

  def poll_url
    if champ.present?
      auto_attach_url
    else
      attachment_path(user_can_edit: true, view_as: @view_as, auto_attach_url: @auto_attach_url, direct_upload: @direct_upload)
    end
  end

  def poll_context
    return :dossier if champ.present?

    nil
  end

  def field_name(object_name = nil, method_name = nil, *method_names, multiple: false, index: nil)
    field_name = @form_object_name || ActiveModel::Naming.param_key(@attached_file.record)
    "#{field_name}[#{attribute_name}]#{'[]' if as_multiple?}"
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

  def replace_button_options
    {
      type: 'button',
      data: {
        action: "click->replace-attachment#open",
        auto_attach_url: auto_attach_url
      }.compact
    }
  end

  def retry_button_options
    {
      type: 'button',
      class: 'fr-btn fr-btn--sm fr-btn--tertiary fr-mt-1w attachment-upload-error-retry',
      data: { input_target: ".#{attachment_input_class}", action: 'autosave#onClickRetryButton' }
    }
  end

  def persisted?
    !!attachment&.persisted?
  end

  def downloadable?(attachment)
    return false unless @view_as == :download

    viewable?(attachment)
  end

  def viewable?(attachment)
    return false if attachment.virus_scanner_error?
    return false if attachment.watermark_pending?

    true
  end

  def error?(attachment)
    attachment.virus_scanner_error?
  end

  def error_message(attachment)
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
      # There is always a single input by champ, its id must match the label "for" attribute.
      return champ.input_id
    end

    helpers.field_id(@form_object_name || @attached_file.record, attribute_name)
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
    @allowed_formats ||= begin
                           formats = content_type_validator.options[:in].filter_map do |content_type|
                             MiniMime.lookup_by_content_type(content_type)&.extension
                           end.uniq.sort_by { EXTENSIONS_ORDER.index(_1) || 999 }

                           # When too many formats are allowed, consider instead manually indicating
                           # above the input a more comprehensive of formats allowed, like "any image", or a simplified list.
                           formats.size > 5 ? [] : formats
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

    fail ArgumentError, "Invalid view_as:#{@view_as}, must be :download or :link" if [:download, :link].exclude?(@view_as)
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
