class DossiersFilter
  attr_reader :user, :params

  ITEMS_PER_PAGE = 25

  def initialize(user, params)
    @user = user
    @params = params.permit(:page, :from_created_at_date, :from_depose_at_date, states: [])
  end

  def filter_params
    params[:from_created_at_date].presence || params[:from_depose_at_date].presence || params[:states].presence
  end

  def filter_params_count
    count = 0
    count += 1 if params[:from_created_at_date].presence
    count += 1 if params[:from_depose_at_date].presence
    count += params[:states].count if params[:states].presence
    count
  end

  def states
    params[:states].compact_blank if params[:states].present?
  end

  def states_filtered?(state)
    states&.include?(state)
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
end
