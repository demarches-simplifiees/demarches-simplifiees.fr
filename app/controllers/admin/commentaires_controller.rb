class Admin::CommentairesController < CommentairesController
  before_action :authenticate_user!
end