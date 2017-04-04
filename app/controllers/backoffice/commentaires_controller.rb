class Backoffice::CommentairesController < CommentairesController
  before_action :authenticate_gestionnaire!

  def is_gestionnaire?
    true
  end
end
