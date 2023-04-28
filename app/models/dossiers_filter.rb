class DossiersFilter
  attr_reader :user, :params

  ITEMS_PER_PAGE = 25

  def initialize(user, params)
    @user = user
    @params = params.permit(:page, :from_publication_date, states: [])
  end

  def states
    params[:states].compact_blank if params[:states].present?
  end

  def states_filtered?(state)
    states&.include?(state)
  end
end
