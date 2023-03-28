class ProceduresFilter
  attr_reader :admin, :params

  ITEMS_PER_PAGE = 25

  def initialize(admin, params)
    @admin = admin
    @params = params.permit(:page, :libelle, :email, :from_publication_date, zone_ids: [], statuses: [])
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

  def libelle
    ActiveRecord::Base.sanitize_sql_like(params[:libelle]).strip if params[:libelle].present?
  end

  def email
    ActiveRecord::Base.sanitize_sql_like(params[:email]).strip if params[:email].present?
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
end
