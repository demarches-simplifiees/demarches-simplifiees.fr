class ApplicationComponent < ViewComponent::Base
  include ViewComponent::Translatable
  include FlipperHelper

  delegate :rich_text_area_tag, :dsfr_icon, to: :helpers

  delegate :administrateur_signed_in?,
           :expert_signed_in?,
           :gestionnaire_signed_in?,
           :instructeur_signed_in?,
           to: :helpers

  delegate :current_user,
           :current_administrateur,
           :current_gestionnaire,
           to: :controller
end
