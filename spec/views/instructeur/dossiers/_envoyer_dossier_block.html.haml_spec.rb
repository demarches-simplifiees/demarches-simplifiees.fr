# frozen_string_literal: true

describe 'instructeurs/dossiers/envoyer_dossier_block', type: :view do
  let(:dossier) { create(:dossier) }

  subject do
    render(
      'instructeurs/dossiers/envoyer_dossier_block',
      dossier: dossier,
      potential_recipients: potential_recipients
    )
  end

  context "there are other instructeurs for the procedure" do
    let(:instructeur) { create(:instructeur, email: 'yop@totomail.fr') }
    let(:potential_recipients) { [instructeur] }

    it do
      is_expected.to match(/props.*#{instructeur.email}/)
      is_expected.to have_css(".fr-btn")
    end
  end

  context "there is no other instructeur for the procedure" do
    let(:potential_recipients) { [] }

    it do
      is_expected.not_to have_css("select")
      is_expected.not_to have_css(".fr-btn")
      is_expected.to have_content("Vous êtes le seul instructeur assigné sur cette démarche")
    end
  end
end
