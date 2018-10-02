require 'features/new_user/dossier_shared_examples.rb'

describe 'Dossier details:' do
  let(:user) { create(:user) }
  let(:procedure) { create(:simple_procedure) }
  let(:dossier) { create(:dossier, :en_construction, :for_individual, :with_commentaires, user: user, procedure: procedure) }

  before do
    visit_dossier dossier
  end

  scenario 'the user can see the summary of the dossier status' do
    expect(page).to have_current_path(dossier_path(dossier))
    expect(page).to have_content(dossier.id)
    expect(page).to have_selector('.status-explanation')
    expect(page).to have_text(dossier.commentaires.last.body)
  end

  describe "the user can see the mean time they are expected to wait" do
    context "when the dossier is in construction" do
      before do
        other_dossier = create(:dossier, :accepte, :for_individual, procedure: procedure, en_construction_at: 10.days.ago, en_instruction_at: Time.now)
        visit dossier_path(dossier)
      end

      it { expect(page).to have_text("Le temps moyen de vérification pour cette démarche est de 10 jours.") }
    end

    context "when the dossier is in instruction" do
      let(:dossier) { create(:dossier, :en_instruction, :for_individual, :with_commentaires, user: user, procedure: procedure) }

      before do
        other_dossier = create(:dossier, :accepte, :for_individual, procedure: procedure, en_instruction_at: 2.months.ago, processed_at: Time.now)
        visit dossier_path(dossier)
      end

      it { expect(page).to have_text("Le temps moyen d’instruction pour cette démarche est de 2 mois.") }
    end
  end

  it_behaves_like 'the user can edit the submitted demande'
  it_behaves_like 'the user can send messages to the instructeur'

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
