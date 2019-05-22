class AttachmentsController < ApplicationController
  before_action :authenticate_logged_user!
  include ActiveStorage::SetBlob

  def show
    @attachment = @blob.attachments.find(params[:id])
    @user_can_upload = params[:user_can_upload]
  end
end
