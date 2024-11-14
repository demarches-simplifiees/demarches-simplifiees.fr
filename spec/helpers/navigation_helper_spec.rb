# frozen_string_literal: true

RSpec.describe NavigationHelper do
  describe '#current_nav_section' do
    subject { helper.current_nav_section }

    context 'when in procedure management section' do
      it 'returns procedure_management for administrateurs action' do
        allow(helper).to receive(:params).and_return({ action: 'administrateurs' })
        expect(subject).to eq('procedure_management')
      end

      it 'returns procedure_management for stats action' do
        allow(helper).to receive(:params).and_return({ action: 'stats' })
        expect(subject).to eq('procedure_management')
      end

      it 'returns procedure_management for email_notifications action' do
        allow(helper).to receive(:params).and_return({ action: 'email_notifications' })
        expect(subject).to eq('procedure_management')
      end

      it 'returns procedure_management for deleted_dossiers action' do
        allow(helper).to receive(:params).and_return({ action: 'deleted_dossiers' })
        expect(subject).to eq('procedure_management')
      end

      it 'returns procedure_management for groupe_instructeurs controller' do
        allow(helper).to receive(:params).and_return({ controller: 'instructeurs/groupe_instructeurs' })
        expect(subject).to eq('procedure_management')
      end
    end

    context 'when in user support section' do
      it 'returns user_support for email_usagers action' do
        allow(helper).to receive(:params).and_return({ action: 'email_usagers' })
        expect(subject).to eq('user_support')
      end

      it 'returns user_support for apercu action' do
        allow(helper).to receive(:params).and_return({ action: 'apercu' })
        expect(subject).to eq('user_support')
      end
    end

    context 'when in downloads section' do
      it 'returns downloads for exports action' do
        allow(helper).to receive(:params).and_return({ action: 'exports' })
        expect(subject).to eq('downloads')
      end

      it 'returns downloads for archives controller' do
        allow(helper).to receive(:params).and_return({ controller: 'instructeurs/archives' })
        expect(subject).to eq('downloads')
      end
    end

    context 'when in no specific section' do
      it 'returns follow_up by default' do
        allow(helper).to receive(:params).and_return({ action: 'show', controller: 'procedures' })
        expect(subject).to eq('follow_up')
      end
    end
  end
end
