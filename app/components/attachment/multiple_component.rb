# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  renders_one :template

  attr_reader :form
  attr_reader :attached_file
  attr_reader :direct_upload
  attr_reader :id
  attr_reader :user_can_destroy

  delegate :count, :empty?, to: :attachments, prefix: true

  def initialize(form:, attached_file:, user_can_destroy: false, direct_upload: true, id: nil)
    @form = form
    @attached_file = attached_file
    @user_can_destroy = user_can_destroy
    @direct_upload = direct_upload
    @id = id

    @attachments = attached_file.attachments || []
  end

  def each_attachment(&block)
    @attachments.each_with_index(&block)
  end

  def can_attach_next?
    return false if @attachments.empty?
    return false if !@attachments.last.persisted?

    true
  end

  def stimulus_controller_name
    "attachment-multiple"
  end

  private

  def attachments
    @attachments
  end
end
