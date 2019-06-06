class AttachmentsController < ApplicationController
  before_action :authenticate_logged_user!
  include ActiveStorage::SetBlob

  def show
    @attachment = @blob.attachments.find(params[:id])
    @user_can_upload = params[:user_can_upload]
  end

  def destroy
    attachment = @blob.attachments.find(params[:id])
    @attachment_id = attachment.id
    attachment.purge_later
    flash.now.notice = 'La pièce jointe a bien été supprimée.'
  end
end
