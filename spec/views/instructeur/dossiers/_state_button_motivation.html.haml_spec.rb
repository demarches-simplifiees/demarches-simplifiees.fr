describe 'gestionnaires/dossiers/state_button_motivation.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_instruction) }

  subject! do
    render(
      'gestionnaires/dossiers/state_button_motivation.html.haml',
      dossier: dossier,
      popup_title: 'Accepter le dossier',
      placeholder: 'Expliquez au demandeur pourquoi ce dossier est accepté (facultatif)',
      popup_class: 'accept',
      process_action: 'accepter',
      title: 'Accepter',
      confirm: "Confirmez-vous l'acceptation ce dossier ?"
    )
  end

  context 'with an attestation preview' do
    let(:dossier) { create :dossier, :accepte, :with_attestation }
    it { expect(rendered).to have_text("Voir l'attestation") }
  end

  context 'without an attestation preview' do
    it { expect(rendered).not_to have_text("Voir l'attestation") }
  end
end
