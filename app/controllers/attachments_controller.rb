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
    @attachment.purge_later
    flash.notice = 'La pièce jointe a bien été supprimée.'

    if params[:dossier_id]
      @champ = find_champ
    else
      @attachment_options = attachment_options
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  private

  def find_champ
    dossier = policy_scope(Dossier).includes(:champs).find(params[:dossier_id])
    dossier.champs.find_by(stable_id: params[:stable_id], row_id: params[:row_id] || Champ::NULL_ROW_ID)
  end

  def attachment_options
    {
      attached_file: @attachment.record.public_send(@attachment.name),
      view_as: params[:view_as]&.to_sym,
      direct_upload: params[:direct_upload] == "true",
      auto_attach_url: params[:direct_upload] == "true" ? params[:auto_attach_url] : nil
    }
  end
end
