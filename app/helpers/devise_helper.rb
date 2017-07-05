module DeviseHelper
  def devise_error_messages!
    if resource.errors.full_messages.any?
      flash.now[:alert] = resource.errors.full_messages
    end
    ''
  end
end
