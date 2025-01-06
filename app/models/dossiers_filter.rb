# frozen_string_literal: true

class DossiersFilter
  attr_reader :user, :params

  def initialize(user, params)
    @user = user
    @params = params.permit(:page, :from_created_at_date, :from_depose_at_date, :state)
  end

  def filter_params
    params[:from_created_at_date].presence || params[:from_depose_at_date].presence || params[:state].presence
  end

  def filter_params_count
    count = 0
    count += 1 if params[:from_created_at_date].presence
    count += 1 if params[:from_depose_at_date].presence
    count += 1 if params[:state].presence
    count
  end

  def filter_procedures(dossiers)
    return dossiers if filter_params.blank?
    dossiers_result = dossiers
    dossiers_result = dossiers_result.where(state: state) if state.present? && state != Dossier::A_CORRIGER
    dossiers_result = dossiers_result.with_pending_corrections if state.present? && state == Dossier::A_CORRIGER
    dossiers_result = exclude_accuse_lecture(dossiers_result) if state.present? && Dossier::TERMINE.include?(state)
    dossiers_result = dossiers_result.where(dossiers: { created_at: from_created_at_date.. }) if from_created_at_date.present?
    dossiers_result = dossiers_result.where(dossiers: { depose_at: from_depose_at_date.. }) if from_depose_at_date.present?
    dossiers_result
  end

  def state
    params[:state]
  end

  def from_created_at_date
    return if params[:from_created_at_date].blank?

    Date.parse(params[:from_created_at_date])
  rescue Date::Error
    nil
  end

  def from_depose_at_date
    return if params[:from_depose_at_date].blank?

    Date.parse(params[:from_depose_at_date])
  rescue Date::Error
    nil
  end

  def exclude_accuse_lecture(dossiers)
    dossiers.joins(:procedure).where.not('dossiers.accuse_lecture_agreement_at IS NULL AND procedures.accuse_lecture = TRUE ')
  end
end
