require 'spec_helper'

describe SignatureService do
  let(:service) { SignatureService }
  let(:message) { { hello: 'World!' }.to_json }
  let(:tampered_message) { { hello: 'Tampered' }.to_json }

  it 'sign and verify' do
    signature = service.sign(message)
    expect(service.verify(signature, message)).to eq(true)
  end

  it 'fails the verification if the message changed' do
    signature = service.sign(message)
    expect(service.verify(signature, tampered_message)).to eq(false)
  end

  it 'fails the verification if the signature changed' do
    other_signature = service.sign(tampered_message)
    expect(service.verify(nil, message)).to eq(false)
    expect(service.verify('', message)).to eq(false)
    expect(service.verify(other_signature, message)).to eq(false)
  end
end
