class CustomRoutes
  def self.load
    Rails.application.routes.draw do
      get "/provider_url" => redirect("https://numerique.gouv.fr/"), as: :provider
    end
  end
end
