describe ActiveStorage::Blob, type: :model do
  subject do
    ActiveStorage::Blob.create_before_direct_upload!(filename: 'test.png',
                                                     byte_size: 1010,
                                                     checksum: '12123',
                                                     content_type: 'text/plain')
  end

  context 'OBJECT_STORAGE_BLOB_PREFIXED_KEY=something' do
    before { allow(ENV).to receive(:[]).with('OBJECT_STORAGE_BLOB_PREFIXED_KEY').and_return('enabled')}

    it 'creates a direct upload with segments' do
      expect(subject.key.split('/').size).to eq(3)
    end
    it 'creates is marked as prefixed_key' do
      expect(subject.prefixed_key).to eq(true)
    end
  end

  context 'OBJECT_STORAGE_BLOB_PREFIXED_KEY inexistant' do
    before { allow(ENV).to receive('OBJECT_STORAGE_BLOB_PREFIXED_KEY').and_return(nil)}

    it 'creates a direct upload without segments' do
      expect(subject.key.split('/').size).to eq(1)
    end

    it 'creates a not prefixed_key' do
      expect(subject.prefixed_key).to eq(nil)
    end
  end
end
