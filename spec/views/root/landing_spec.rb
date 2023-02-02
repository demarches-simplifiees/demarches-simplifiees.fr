describe 'root/landing.html.haml', type: :view do
  subject { render }

  it "should contains polynesian links" do
    expect(subject).to have_link('Comment trouver ma démarche', href: LISTE_DES_DEMARCHES_URL)
  end
end
