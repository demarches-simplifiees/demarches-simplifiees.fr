describe ActiveStorage::DownloadableFile do
  let(:dossier) { create(:dossier, :en_construction) }
  let(:user_profile) { administrateurs(:default_admin) }
  let(:dossiers) { Dossier.where(id: dossier.id) }
  subject(:list) { ActiveStorage::DownloadableFile.create_list_from_dossiers(user_profile:, dossiers:) }

  describe 'create_list_from_dossiers' do
    context 'when no piece_justificative is present' do
      it { expect(list.length).to eq 1 }
      it { expect(list.first[0].name).to eq "pdf_export_for_instructeur" }
    end
  end

  describe '.cleanup_list_from_dossier' do
    context 'active_storage.service test' do
      before { Rails.application.config.active_storage.service = :test }
      it 'returns the list' do
        list = [:a, :b, :c]
        result = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(list)
        expect(list).to eq(result)
      end
    end

    context 'active_storage.service local' do
      before { Rails.application.config.active_storage.service = :local }
      after { Rails.application.config.active_storage.service = :test }
      it 'returns the list' do
        list = [:a, :b, :c]
        result = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(list)
        expect(list).to eq(result)
      end
    end

    context 'active_storage.service openstack' do
      let(:object_storage_container) { 'object_storage' }
      let(:available_blob_key) { 'available' }
      let(:unavailable_blob_key) { 'broken' }
      let(:active_storage_client) { double }
      let(:active_storage_service) { double(container: object_storage_container) }

      before do
        require 'fog/openstack'
        Rails.application.config.active_storage.service = :openstack

        allow(ActiveStorage::DownloadableFile).to receive(:client).and_return(active_storage_client)
      end
      after { Rails.application.config.active_storage.service = :test }

      it 'returns the list' do
        available_blob = double(key: available_blob_key)
        unavailable_blob = double(key: unavailable_blob_key)
        [available_blob, unavailable_blob].map do |attachment|
          allow(attachment).to receive(:service).and_return(active_storage_service)
        end
        expect(active_storage_client).to receive(:head_object).with(object_storage_container, available_blob_key).and_return(true)
        expect(active_storage_client).to receive(:head_object).with(object_storage_container, unavailable_blob_key).and_raise(Fog::OpenStack::Storage::NotFound.new('Object storage 99.99% availability leave space to 0.01% failure'))

        list = [
          [instance_double(ActiveStorage::Attachment, blob: available_blob), 'filename.pdf'],
          [instance_double(ActiveStorage::Attachment, blob: unavailable_blob), 'filename.pdf']
        ]

        result = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(list)
        expect(result.size).to eq(1)
        expect(result.first.first.blob.key).to eq(available_blob_key)
      end
    end
  end
end
