describe 'Dossier details:' do
  let(:user) { create(:user) }
  let(:simple_procedure) do
    tdcs = [create(:type_de_champ, libelle: 'texte obligatoire')]
    create(:procedure, :published, :for_individual, types_de_champ: tdcs)
  end
  let(:dossier) { create(:dossier, :en_construction, :for_individual, :with_commentaires, user: user, procedure: simple_procedure) }

  before do
    Flipflop::FeatureSet.current.test!.switch!(:new_dossier_details, true)
  end

  after do
    Flipflop::FeatureSet.current.test!.switch!(:new_dossier_details, false)
  end

  scenario 'the user can see the summary of the dossier status' do
    visit_dossier dossier

    expect(page).to have_current_path(dossier_path(dossier))
    expect(page).to have_content(dossier.id)
    expect(page).to have_selector('.status-explanation')
    expect(page).to have_text(dossier.commentaires.last.body)
  end

  describe "the user can see the mean time they are expected to wait" do
    context "the dossier is in construction" do
      before do
        other_dossier = create(:dossier, :accepte, :for_individual, procedure: simple_procedure, en_construction_at: 10.days.ago, en_instruction_at: Time.now)
      end

      it "show the proper wait time" do
        visit_dossier dossier

        expect(page).to have_text("Le temps moyen de vérification pour cette démarche est de 10 jours.")
      end
    end

    context "the dossier is in instruction" do
      let(:dossier) { create(:dossier, :en_instruction, :for_individual, :with_commentaires, user: user, procedure: simple_procedure) }

      before do
        other_dossier = create(:dossier, :accepte, :for_individual, procedure: simple_procedure, en_instruction_at: 2.months.ago, processed_at: Time.now)
      end

      it "show the proper wait time" do
        visit_dossier dossier

        expect(page).to have_text("Le temps moyen d’instruction pour cette démarche est de 2 mois.")
      end
    end
  end

  scenario 'the user can see and edit dossier before instruction' do
    visit_dossier dossier
    click_on 'Demande'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    click_on 'Modifier le dossier'

    expect(page).to have_current_path(modifier_dossier_path(dossier))
    fill_in('texte obligatoire', with: 'Nouveau texte')
    click_on 'Enregistrer les modifications du dossier'

    expect(page).to have_current_path(demande_dossier_path(dossier))
    expect(page).to have_content('Nouveau texte')
  end

  context 'with messages' do
    let!(:commentaire) { create(:commentaire, dossier: dossier, email: 'instructeur@exemple.fr', body: 'Message envoyé à l’usager') }
    let(:message_body) { 'Message envoyé à l’instructeur' }

    scenario 'the user can send a message' do
      visit_dossier dossier
      click_on 'Messagerie'

      expect(page).to have_current_path(messagerie_dossier_path(dossier))
      expect(page).to have_content(commentaire.body)

      fill_in 'commentaire_body', with: message_body
      click_on 'Envoyer'

      expect(page).to have_current_path(messagerie_dossier_path(dossier))
      expect(page).to have_content('Message envoyé')
      expect(page).to have_content(commentaire.body)
      expect(page).to have_content(message_body)
    end
  end

  private

  def visit_dossier(dossier)
    visit dossier_path(dossier)

    expect(page).to have_current_path(new_user_session_path)
    fill_in 'user_email', with: user.email
    fill_in 'user_password', with: user.password
    click_on 'Se connecter'

    expect(page).to have_current_path(dossier_path(dossier))
  end
end
