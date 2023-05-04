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
end
