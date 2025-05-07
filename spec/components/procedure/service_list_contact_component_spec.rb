# frozen_string_literal: true

RSpec.describe Procedure::ServiceListContactComponent, type: :component do
  let(:dossier) { create(:dossier) }

  describe 'rendering with different service types' do
    subject { render_inline(described_class.new(service_or_contact_information: service_or_contact_information, dossier: dossier)) }

    context 'when using a Service object' do
      let(:service_or_contact_information) do
        create(:service,
          email: 'service@example.com',
          telephone: '0123456789',
          horaires: 'Du lundi au vendredi de 9h à 17h',
          faq_link: 'https://example.com/faq',
          contact_link: 'https://example.com/contact',
          other_contact_info: 'Fermé les jours fériés')
      end

      it 'renders contact information correctly' do
        expect(subject).to have_link(href: 'https://example.com/faq')
        expect(subject).to have_link(href: 'https://example.com/contact')
        expect(subject).to have_link('service@example.com', href: 'mailto:service@example.com')
        expect(subject).to have_link('0123456789')
        expect(subject).to have_text('Du lundi au vendredi de 9h à 17h')
        expect(subject).to have_text('Fermé les jours fériés')
      end
    end

    context 'when using a ContactInformation object' do
      let(:service_or_contact_information) do
        create(:contact_information,
          email: 'contact@example.com',
          telephone: '0876543210',
          horaires: 'Du mardi au samedi de 10h à 18h')
      end

      it 'renders contact information correctly' do
        expect(subject).to have_link('contact@example.com', href: 'mailto:contact@example.com')
        expect(subject).to have_link('0876543210')
        expect(subject).to have_text('Du mardi au samedi de 10h à 18h')
        expect(subject).not_to have_text('other_contact_info')
      end
    end

    context 'when dossier has messagerie available' do
      let(:service_or_contact_information) { create(:service) }

      before do
        allow(dossier).to receive(:messagerie_available?).and_return(true)
      end

      it 'renders the contact instructeur link' do
        expect(subject).to have_link("Envoyez directement un message à l’instructeur")
      end
    end
  end
end
