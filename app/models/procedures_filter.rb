class ProceduresFilter
  attr_reader :admin, :params

  ITEMS_PER_PAGE = 25

  def initialize(admin, params)
    @admin = admin
    @params = params.permit(:page, :from_publication_date, :view_admins, zone_ids: [], statuses: [])
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

  def view_admins?
    params[:view_admins] == 'true'
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

  def with_view_admins(view_admins)
    params.to_h.merge(view_admins: view_admins)
  end

  def procedures_result
    return @procedures_result if @procedures_result
    @procedures_result = paginate(filter_procedures, published_at: :desc)
  end

  def admins_result
    return @admins_result if @admins_result
    @admins_result = Administrateur.includes(:user).where(id: AdministrateursProcedure.where(procedure: filter_procedures).select(:administrateur_id))
    @admins_result = paginate(@admins_result, 'users.email')
  end

  private

  def filter_procedures
    procedures_result = Procedure.joins(:procedures_zones).publiees_ou_closes
    procedures_result = procedures_result.where(procedures_zones: { zone_id: zone_ids }) if zone_ids.present?
    procedures_result = procedures_result.where(aasm_state: statuses) if statuses.present?
    procedures_result = procedures_result.where('published_at >= ?', from_publication_date) if from_publication_date.present?
    procedures_result
  end

  def paginate(result, ordered_by)
    result.page(params[:page]).per(ITEMS_PER_PAGE).order(ordered_by)
  end
end
