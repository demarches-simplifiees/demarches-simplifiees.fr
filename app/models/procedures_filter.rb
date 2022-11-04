class ProceduresFilter
  attr_reader :admin, :params

  ITEMS_PER_PAGE = 25

  def initialize(admin, params)
    @admin = admin
    @params = params.permit(:from_publication_date, zone_ids: [], statuses: [])
  end

  def admin_zones
    @admin_zones ||= admin.zones
  end

  def other_zones
    @other_zones ||= Zone.all - admin_zones
  end

  def zone_ids
    params[:zone_ids].compact_blank if params[:zone_ids].present?
  end

  def selected_zones
    Zone.where(id: zone_ids) if zone_ids.present?
  end

  def statuses
    params[:statuses].compact_blank if params[:statuses].present?
  end

  def from_publication_date
    return if params[:from_publication_date].blank?

    Date.parse(params[:from_publication_date])
  rescue Date::Error
    nil
  end

  def zone_filtered?(zone_id)
    zone_ids&.map(&:to_i)&.include?(zone_id)
  end

  def status_filtered?(status)
    statuses&.include?(status)
  end

  def without(filter, value = nil)
    if value.nil?
      params.to_h.except(filter)
    else
      new_filter = params.to_h[filter] - [value.to_s]
      params.to_h.merge(filter => new_filter)
    end
  end

  def procedures_result
    return @procedures_result if @procedures_result
    @procedures_result = Procedure.joins(:procedures_zones).publiees_ou_closes
    @procedures_result = @procedures_result.where(procedures_zones: { zone_id: zone_ids }) if zone_ids.present?
    @procedures_result = @procedures_result.where(aasm_state: statuses) if statuses.present?
    @procedures_result = @procedures_result.where('published_at >= ?', from_publication_date) if from_publication_date.present?
    @procedures_result = @procedures_result.page(params[:page]).per(ITEMS_PER_PAGE).order(published_at: :desc)
  end
end
