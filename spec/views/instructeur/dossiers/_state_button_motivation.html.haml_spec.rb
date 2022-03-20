describe 'instructeurs/dossiers/state_button_motivation.html.haml', type: :view do
  let(:dossier) { create(:dossier, :en_instruction) }

  subject do
    render(
      'instructeurs/dossiers/state_button_motivation.html.haml',
      dossier: dossier,
      popup_title: 'Accepter le dossier',
      placeholder: 'Expliquez au demandeur pourquoi ce dossier est accepté (facultatif)',
      popup_class: 'accept',
      process_action: 'accepter',
      title: 'Accepter',
      confirm: "Confirmez-vous l'acceptation ce dossier ?"
    )
  end

  context 'without attestation' do
    it { expect(subject).not_to have_link(href: apercu_attestation_instructeur_dossier_path(dossier.procedure, dossier)) }
  end

  context 'with an attestation' do
    let(:dossier) { create :dossier, :accepte, :with_attestation }

    it 'includes a link to preview the attestation' do
      expect(subject).to have_link(href: apercu_attestation_instructeur_dossier_path(dossier.procedure, dossier))
    end
  end

  context 'with an attestation from different revision' do
    let(:procedure) { create(:procedure, :published, attestation_template: create(:attestation_template)) }
    let(:revision) { procedure.revisions.first }
    let(:dossier) { create(:dossier, :en_instruction, procedure: procedure, revision: revision) }

    before do
      procedure.draft_revision.attestation_template = procedure.draft_revision.attestation_template.dup
      procedure.draft_revision.attestation_template.title = "Nouveau titre"
      procedure.draft_revision.attestation_template.save!
      procedure.publish_revision!
    end

    it 'includes a warning about outdated attestation template' do
      expect(subject).to have_content('L’attestation qui sera générée comporte des modifications')
    end
  end
end
