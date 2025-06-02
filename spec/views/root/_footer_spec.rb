# frozen_string_literal: true

describe 'root/_footer.html.haml', type: :view do
  subject { render }

  it "should contains polynesian links" do
    expect(subject).to have_link("la direction des talents et de l'innovation (DTI)", href: 'https://www.fonction-publique.gov.pf/')
    expect(subject).to have_link('CGU', href: CGU_URL)
    expect(subject).to have_link('Données personnelles', href: RGPD_URL)
    expect(subject).to have_link('Mentions légales', href: MENTIONS_LEGALES_URL)
    expect(subject).to have_link('Documentation', href: DOC_URL)
    expect(CGU_URL).to include('mes-demarches.gitbook.io')
    expect(RGPD_URL).to include('mes-demarches.gitbook.io')
    expect(DOC_URL).to include('mes-demarches.gitbook.io')
  end

  it 'should not contain french links with no polynesian equivalent' do
    expect(subject).not_to have_link('Newsletter', href: 'https://my.sendinblue.com/users/subscribe/js_id/3s2q1/id/1')
    expect(subject).not_to have_link('Nouveautés', href: 'https://github.com/betagouv/tps/releases')
  end
end
