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
    champ = @blob.attachments.first.record
    champ = nil unless champ.is_a?(Champ) && champ.private?

    @attachment = @blob.attachments.find(params[:id])
    @attachment.purge_later

    if champ
      ChampRevision.create_or_update_revision(champ, current_instructeur.id)
    end

    flash.notice = 'La pièce jointe a bien été supprimée.'

    @champ_id = params[:champ_id]

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: root_url) }
    end
  end
end
