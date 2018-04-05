require 'spec_helper'

describe SignatureService do
  let(:service) { SignatureService }
  let(:message) { { hello: 'World!' }.to_json }
  let(:message2) { { hello: 'World' }.to_json }

  it "sign and verify" do
    signature = service.sign(message)
    signature2 = service.sign(message2)

    expect(service.verify(signature, message)).to eq(true)
    expect(service.verify(signature2, message)).to eq(false)
    expect(service.verify(signature, message2)).to eq(false)
  end
end
