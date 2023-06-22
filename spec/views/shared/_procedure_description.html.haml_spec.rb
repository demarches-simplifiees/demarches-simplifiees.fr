describe 'shared/_procedure_description', type: :view do
  let(:estimated_duration_visible) { true }
  let(:procedure) { create(:procedure, :published, :with_service, estimated_duration_visible:) }

  subject { render partial: 'shared/procedure_description', locals: { procedure: procedure } }

  it 'renders the view' do
    subject
    expect(rendered).to have_selector('.procedure-logos')
    expect(rendered).to have_text(procedure.libelle)
    expect(rendered).to have_text(procedure.description)
    expect(rendered).to have_text('Temps de remplissage estimé')
    expect(rendered).not_to have_text('Quelles sont les pièces justificatives à fournir')
  end

  context 'procedure with estimated duration not visible' do
    let(:estimated_duration_visible) { false }
    it 'hides the estimated duration' do
      subject
      expect(rendered).not_to have_text('Temps de remplissage estimé')
    end
  end

  it 'does not show empty date limite' do
    subject
    expect(rendered).not_to have_text('Date limite')
  end

  context 'when the procedure has an auto_archive date' do
    let(:procedure) { create(:procedure, :published, :with_service, :with_auto_archive) }
    it 'shows the auto_archive_on' do
      subject
      expect(rendered).to have_text('Date limite')
    end
  end

  context 'when the procedure has pieces jointes' do
    let(:procedure) { create(:procedure, :draft, :with_titre_identite, :with_piece_justificative, :with_siret) }
    it 'shows the pieces jointes list for draft procedure' do
      subject
      expect(rendered).to have_text('Quelles sont les pièces justificatives à fournir')
      expect(rendered).to have_text('Libelle du champ')
      expect(rendered).to have_selector('.pieces_jointes ul li', count: 2)
    end

    it 'shows the pieces jointes list for published procedure' do
      procedure.publish!
      subject
      expect(rendered).to have_text('Quelles sont les pièces justificatives à fournir')
      expect(rendered).to have_text('Libelle du champ')
      expect(rendered).to have_selector('.pieces_jointes ul li', count: 2)
    end

    it 'shows the manual description pieces jointes list if admin filled one' do
      procedure.update!(description_pj: 'une description des pj manuelle')
      subject
      expect(rendered).to have_text('Quelles sont les pièces justificatives à fournir')
      expect(rendered).to have_text('une description des pj manuelle')
    end
  end
end
