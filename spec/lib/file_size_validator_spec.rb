require 'spec_helper'

describe FileSizeValidator, lib: true do
  let(:validator) { FileSizeValidator.new(options) }
  let(:attachment) { CerfaUploader.new }
  let(:note) { create(:cerfa) }

  describe 'options uses an integer' do
    let(:options) { { maximum: 10, attributes: { content: attachment } } }

    it 'attachment exceeds maximum limit' do
      allow(attachment).to receive(:size) { 100 }
      validator.validate_each(note, :content, attachment)
      expect(note.errors).to have_key(:content)
    end

    it 'attachment under maximum limit' do
      allow(attachment).to receive(:size) { 1 }
      validator.validate_each(note, :content, attachment)
      expect(note.errors).not_to have_key(:content)
    end
  end

  describe 'options uses a symbol' do
    let(:options) do
      {
        maximum: :test,
        attributes: { content: attachment }
      }
    end

    before do
      allow(note).to receive(:test) { 10 }
    end

    it 'attachment exceeds maximum limit' do
      allow(attachment).to receive(:size) { 100 }
      validator.validate_each(note, :content, attachment)
      expect(note.errors).to have_key(:content)
    end

    it 'attachment under maximum limit' do
      allow(attachment).to receive(:size) { 1 }
      validator.validate_each(note, :content, attachment)
      expect(note.errors).not_to have_key(:content)
    end
  end
end
