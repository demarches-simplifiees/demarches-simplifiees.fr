class User::CustomFailure < Devise::FailureApp
  def redirect_url
    url_for(controller: '/start', action: :index)
  end

  # You need to override respond to eliminate recall
  def respond
    if http_auth?
      http_auth
    else
      redirect
    end
  end
end
