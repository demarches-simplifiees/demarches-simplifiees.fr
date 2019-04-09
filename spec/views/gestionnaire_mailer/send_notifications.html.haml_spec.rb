require 'rails_helper'

describe 'gestionnaire_mailer/send_notifications.html.haml', type: :view do
  let(:gestionnaire) { create(:gestionnaire) }

  before do
    assign(:data, data)

    render
  end

  context 'when there is one dossier in contruction' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 1,
          nb_notification: 0
        }
      ]
    end

    it { expect(rendered).to have_link('une superbe démarche', href: procedure_url(213)) }
    it { expect(rendered).to have_text('une superbe démarche') }
    it { expect(rendered).to have_text('1 dossier en construction') }
    it { expect(rendered).not_to have_text('notification') }
  end

  context 'when there is one notification' do
    let(:data) do
      [
        {
          procedure_libelle: 'une superbe démarche',
          procedure_id: 213,
          nb_en_construction: 0,
          nb_notification: 1
        }
      ]
    end

    it { expect(rendered).not_to have_text('en construction') }
    it { expect(rendered).to have_text('1 notification') }
  end
end
