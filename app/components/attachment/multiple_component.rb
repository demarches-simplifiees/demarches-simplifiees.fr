# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  DEFAULT_MAX_ATTACHMENTS = 10

  renders_one :template

  attr_reader :attached_file
  attr_reader :attachments
  attr_reader :champ
  attr_reader :form_object_name
  attr_reader :max
  attr_reader :user_can_destroy
  attr_reader :user_can_download
  alias user_can_download? user_can_download

  delegate :count, :empty?, to: :attachments, prefix: true

  def initialize(champ:, attached_file:, form_object_name: nil, user_can_download: false, user_can_destroy: true, max: nil)
    @champ = champ
    @attached_file = attached_file
    @form_object_name = form_object_name
    @user_can_download = user_can_download
    @user_can_destroy = user_can_destroy
    @max = max || DEFAULT_MAX_ATTACHMENTS

    @attachments = attached_file.attachments || []
  end

  def each_attachment(&block)
    @attachments.each_with_index(&block)
  end

  def can_attach_next?
    @attachments.count < @max
  end

  def empty_component_id
    "attachment-multiple-empty-#{champ.id}"
  end

  def auto_attach_url
    helpers.auto_attach_url(champ)
  end
  alias poll_url auto_attach_url
end
