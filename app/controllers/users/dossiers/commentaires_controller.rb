class Users::Dossiers::CommentairesController < CommentairesController
  before_action :authenticate_user!
end