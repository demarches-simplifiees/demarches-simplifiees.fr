# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  DEFAULT_MAX_ATTACHMENTS = 10

  renders_one :template

  attr_reader :attached_file
  attr_reader :attachments
  attr_reader :champ
  attr_reader :form_object_name
  attr_reader :max
  attr_reader :view_as
  attr_reader :user_can_destroy
  alias user_can_destroy? user_can_destroy
  attr_reader :user_can_replace
  alias user_can_replace? user_can_replace

  delegate :count, :empty?, to: :attachments, prefix: true

  def initialize(champ: nil, attached_file:, form_object_name: nil, view_as: :link, user_can_destroy: true, user_can_replace: false, max: nil)
    @champ = champ
    @attached_file = attached_file
    @form_object_name = form_object_name
    @view_as = view_as
    @user_can_destroy = user_can_destroy
    @user_can_replace = user_can_replace
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
    champ.present? ? "attachment-multiple-empty-#{champ.id}" : "attachment-multiple-empty-generic"
  end

  def auto_attach_url
    champ.present? ? helpers.auto_attach_url(champ) : '#'
  end
  alias poll_url auto_attach_url

  def poll_context
    return :dossier if champ.present?

    nil
  end

  def replace_controller_attributes
    return {} unless user_can_replace?

    {
      "data-controller": 'replace-attachment'
    }
  end
end
