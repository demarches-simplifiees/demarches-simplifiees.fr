describe 'shared/dossiers/france_connect_informations.html.haml', type: :view do
  subject do
    render(
      'shared/dossiers/france_connect_informations.html.haml',
      user_information: user_information
    )
  end

  context "with complete france_connect information" do
    let(:user_information) { build(:france_connect_information, updated_at: Time.zone.now) }
    it {
      expect(subject).to have_text("Le dossier a été déposé par le compte de #{user_information.given_name} #{user_information.family_name}, authentifié par FranceConnect le #{user_information.updated_at.strftime('%d/%m/%Y')}")
    }
  end

  context "with missing updated_at" do
    let(:user_information) { build(:france_connect_information, updated_at: nil) }

    it {
      expect(subject).to have_text("Le dossier a été déposé par le compte de #{user_information.given_name} #{user_information.family_name}")
      expect(subject).not_to have_text("authentifié par FranceConnect le ")
    }
  end

  context "with missing given_name" do
    let(:user_information) { build(:france_connect_information, given_name: nil) }

    it {
      expect(subject).to have_text("Le dossier a été déposé par le compte de #{user_information.family_name}")
    }
  end

  context "with all names missing" do
    let(:user_information) { build(:france_connect_information, given_name: nil, family_name: nil) }

    it {
      expect(subject).to have_text("Le dossier a été déposé par un compte FranceConnect.")
    }
  end
end
