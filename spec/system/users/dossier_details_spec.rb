require 'system/users/dossier_shared_examples.rb'

describe 'Dossier details:' do
  let(:user) { create(:user) }
  let(:procedure) { create(:simple_procedure) }
  let(:dossier) { create(:dossier, :en_construction, :with_individual, :with_commentaires, user: user, procedure: procedure) }

  before do
    visit_dossier dossier
  end

  scenario 'the user can see the summary of the dossier status' do
    expect(page).to have_current_path(dossier_path(dossier))
    expect(page).to have_content(dossier.id)
    expect(page).to have_selector('.status-explanation')
    expect(page).to have_text(dossier.commentaires.last.body)
  end

  context 'when the deposit receipt feature is enabled' do
    before { Flipper.enable(:procedure_dossier_papertrail, procedure) }
    after { Flipper.disable(:procedure_dossier_papertrail, procedure) }

    it 'displays a link to download a deposit receipt' do
      visit dossier_path(dossier)
      expect(page).to have_link("Obtenir une attestation de dépôt de dossier", href: %r{dossiers/#{dossier.id}/papertrail.pdf})
    end
  end

  describe "the user can see the mean time they are expected to wait" do
    let(:other_dossier) { create(:dossier, :accepte, :with_individual, procedure: procedure, depose_at: 10.days.ago, en_instruction_at: 9.days.ago, processed_at: Time.zone.now) }

    context "when the dossier is in construction" do
      it "displays the estimated wait duration" do
        other_dossier
        visit dossier_path(dossier)
        expect(page).to have_text("Habituellement, les dossiers de cette démarche sont traités dans un délai de 10 jours.")
      end
    end

    context "when the dossier is in instruction" do
      let(:dossier) { create(:dossier, :en_instruction, :with_individual, :with_commentaires, user: user, procedure: procedure) }

      it "displays the estimated wait duration" do
        other_dossier
        visit dossier_path(dossier)
        expect(page).to have_text("Habituellement, les dossiers de cette démarche sont traités dans un délai de 10 jours.")
      end
    end
  end

  scenario 'the user is redirected from old URLs' do
    visit "/users/dossiers/#{dossier.id}/recapitulatif"
    expect(page).to have_current_path(dossier_path(dossier))
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
