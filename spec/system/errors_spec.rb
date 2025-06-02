# frozen_string_literal: true

describe 'Errors handling', js: false do
  let(:procedure) { create(:procedure) }

  scenario 'bug renders dynamic 500 page' do
    procedure.revisions.destroy_all # break procedure

    without_detailed_exceptions do
      visit commencer_path(path: procedure.path)
    end

    expect(page).to have_http_status(:internal_server_error)
    expect(page).to have_content('une erreur est survenue')
    expect(page).to have_content('Se connecter')
    expect(page).to have_link('Contactez-nous')
  end

  scenario 'fatal error fallback to static 500 page' do
    without_detailed_exceptions do
      Rails.application.env_config["action_dispatch.cookies"] = "will fail"
      visit commencer_path(path: procedure.path)
    ensure
      Rails.application.env_config.delete("action_dispatch.cookies")
    end

    expect(page).to have_content('une erreur est survenue')
    expect(page).not_to have_content('Se connecter')
    expect(page).to have_link('Contactez-nous')
  end
end
