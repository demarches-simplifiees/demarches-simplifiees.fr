require 'spec_helper'

feature 'As a User I can send invitations from dossiers', js: true do

  let(:user)           { create(:user) }
  let(:procedure_1)    { create(:procedure, :with_type_de_champ, libelle: 'procedure 1') }

  before 'Assign procedures to Accompagnateur and generating dossiers for each' do
    Dossier.create(procedure_id: procedure_1.id.to_s, user: user, state: 'initiated')
    login_as user, scope: :user
    visit users_dossier_recapitulatif_path(1)
  end

  context 'On dossier show' do

    scenario 'Sending invitation' do
      page.find('#invitations').click
      fill_in 'invitation-email', with: 'toto@email.com'
      page.find('#send-invitation .btn-success').trigger('click')
      save_and_open_page
    end

  end
end
