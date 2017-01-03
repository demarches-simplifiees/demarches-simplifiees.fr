require 'spec_helper'

feature 'As an Accompagnateur I can send invitations from dossiers', js: true do

  let(:user)           { create(:user) }
  let(:gestionnaire)   { create(:gestionnaire) }
  let(:procedure_1)    { create(:procedure, :with_type_de_champ, libelle: 'procedure 1') }

  before 'Assign procedures to Accompagnateur and generating dossiers for each' do
    create :assign_to, gestionnaire: gestionnaire, procedure: procedure_1
    Dossier.create(procedure_id: procedure_1.id.to_s, user: user, state: 'initiated')
    login_as gestionnaire, scope: :gestionnaire
    visit backoffice_dossier_path(1)
  end

  context 'On dossier show' do

    scenario 'Sending invitation' do
      page.find('#invitations').click
      page.find('#invitation-email').set('toto@email.com')
      page.find('#send-invitation .btn-success').trigger('click')
    end

  end
end
