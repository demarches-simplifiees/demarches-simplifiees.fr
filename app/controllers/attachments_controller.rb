# frozen_string_literal: true

class AttachmentsController < ApplicationController
  before_action :authenticate_logged_user!
  include ActiveStorage::SetBlob
  before_action :set_attachment
  before_action :ensure_legitimate_access, only: :destroy

  def show
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
    if champ?
      @attachment = champ.piece_justificative_file.find { _1.blob.id == @blob.id }
      if @attachment.present?
        champ.reset_external_data! if champ.may_reset_external_data?

        @attachment.purge_later
        champ.update_timestamps
      end
      champ.piece_justificative_file.reload
      flash.notice = t("activerecord.models.attachment.successfully_deleted_with_anchor", attachment: @attachment.blob.filename, champ: @champ.focusable_input_id)
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

  def ensure_legitimate_access
    return if an_user_or_invite_change_its_dossier?
    return if an_instructeur_change_a_private_attachment?
    return if an_administrateur_change_its_procedure?
    return if an_expert_change_its_avis?

    head :not_found
  end

  def set_attachment
    @attachment = @blob.attachments.find(params[:id])
  end

  def user_or_invite_changing_its_dossier?
    champ&.public? && current_user.owns_or_invite?(champ.dossier)
  end

  def instructeur_changing_a_private_attachment?
    champ&.private? && current_user.instructeur? && current_instructeur.in?(champ.dossier.groupe_instructeur.instructeurs)
  end

  def admin_changing_its_procedure?
    procedure? && current_user.administrateur? && current_administrateur.in?(record.administrateurs)
  end

  def an_expert_change_its_avis?
    avis? && current_expert == record.expert
  end

  def record = @attachment.record
  def champ? = record.is_a?(Champ)
  def procedure? = record.is_a?(Procedure)
  def avis? = record.is_a?(Avis)

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
