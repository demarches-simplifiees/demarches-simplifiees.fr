# frozen_string_literal: true

class AttachmentsController < ApplicationController
  before_action :authenticate_logged_user!
  include ActiveStorage::SetBlob

  def show
    @attachment = @blob.attachments.find(params[:id])

    @user_can_edit = cast_bool(params[:user_can_edit])
    @direct_upload = cast_bool(params[:direct_upload])
    @view_as = params[:view_as]&.to_sym
    @auto_attach_url = params[:auto_attach_url]

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  def destroy
    @attachment = @blob.attachments.find(params[:id])

    if champ?
      @attachment = champ.piece_justificative_file.find { _1.blob.id == @blob.id }
      if @attachment.present?
        @attachment.purge_later
        champ.update_timestamps
      end
      champ.piece_justificative_file.reload
      flash.notice = t("activerecord.models.attachment.successfully_deleted_with_anchor", attachment: @attachment.blob.filename, champ: @champ.input_id)
    else
      @attachment.purge_later
      @attachment_options = attachment_options
      flash.notice = t("activerecord.models.attachment.successfully_deleted_without_anchor", attachment: @attachment.blob.filename)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  private

  def record
    @attachment.record
  end

  def champ?
    record.is_a?(Champ)
  end

  def champ
    @champ ||= if champ?
      record.dossier.with_update_stream(current_user) if record.public?
      record.dossier.champ_for_update(record.type_de_champ, row_id: record.row_id, updated_by: current_user.email)
    end
  end

  def attachment_options
    {
      attached_file: record.public_send(@attachment.name),
      view_as: params[:view_as]&.to_sym,
      direct_upload: params[:direct_upload] == "true",
      auto_attach_url: params[:direct_upload] == "true" ? params[:auto_attach_url] : nil
    }
  end
end
