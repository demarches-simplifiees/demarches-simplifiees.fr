# frozen_string_literal: true

describe 'instructeur_mailer/send_notifications', type: :view do
  let(:instructeur) { create(:instructeur) }

  before do
    assign(:data, data)

    allow(Current).to receive(:application_name).and_return(APPLICATION_NAME)

    render
  end

  context 'when there is one dossier in contruction' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 1,
          nb_en_instruction: 0,
          nb_accepted: 0,
          nb_notification: 0
        }
      ]
    end

    it { expect(rendered).to have_link('une superbe démarche', href: instructeur_procedure_url(213)) }
    it { expect(rendered).to have_text('une superbe démarche') }
    it { expect(rendered).to have_text('1 dossier en construction') }
    it { expect(rendered).not_to have_text('notification') }
  end

  context 'when there is one declarated dossier in instruction' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 0,
          nb_en_instruction: 1,
          nb_accepted: 0,
          nb_notification: 0
        }
      ]
    end

    it { expect(rendered).to have_link('une superbe démarche', href: instructeur_procedure_url(213)) }
    it { expect(rendered).to have_text('une superbe démarche') }
    it { expect(rendered).to have_text('1 dossier') }
    it { expect(rendered).not_to have_text('notification') }
    it { expect(rendered).not_to have_text('construction') }
    it { expect(rendered).not_to have_text('accepte') }
  end

  context 'when there is one declarated dossier in accepte' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 0,
          nb_en_instruction: 0,
          nb_accepted: 1,
          nb_notification: 0
        }
      ]
    end

    it { expect(rendered).to have_link('une superbe démarche', href: instructeur_procedure_url(213)) }
    it { expect(rendered).to have_text('une superbe démarche') }
    it { expect(rendered).to have_text('1 dossier') }
    it { expect(rendered).not_to have_text('notification') }
    it { expect(rendered).not_to have_text('construction') }
    it { expect(rendered).not_to have_text('instruction') }
  end

  context 'when there is one notification' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 0,
          nb_en_instruction: 0,
          nb_accepted: 0,
          nb_notification: 1
        }
      ]
    end

    it { expect(rendered).not_to have_text('en construction') }
    it { expect(rendered).to have_text('1 notification') }
  end
end
