class AttachmentsController < ApplicationController
  before_action :authenticate_logged_user!
  include ActiveStorage::SetBlob

  def show
    @attachment = @blob.attachments.find(params[:id])
    @user_can_upload = params[:user_can_upload]

    respond_to do |format|
      format.js
      format.html { redirect_back(fallback_location: root_url) }
    end
  end

  def destroy
    attachment = @blob.attachments.find(params[:id])
    @attachment_id = attachment.id
    attachment.purge_later
    flash.now.notice = 'La pièce jointe a bien été supprimée.'
  end
end
