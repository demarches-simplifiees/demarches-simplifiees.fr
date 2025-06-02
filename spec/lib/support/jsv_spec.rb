# frozen_string_literal: true

require_relative "../../../lib/support/jsv"

describe ".to_jsv support" do
  it "converts a Hash to JSV" do
    expect({}.to_jsv).to eq("{}")
    expect({ "a" => "b" }.to_jsv).to eq("{a:b}")
  end

  it "converts an Array to JSV" do
    expect([].to_jsv).to eq("[]")
    expect(["a", "b"].to_jsv).to eq("[a,b]")
  end

  it "converts a String to JSV" do
    expect("".to_jsv).to eq("")
    expect("a".to_jsv).to eq("a")

    # escape special characters
    expect("a[b".to_jsv).to eq('"a[b"')
    expect("a]b".to_jsv).to eq('"a]b"')
    expect("a,b".to_jsv).to eq('"a,b"')
    expect("a{b".to_jsv).to eq('"a{b"')
    expect("a}b".to_jsv).to eq('"a}b"')
    expect('a"b'.to_jsv).to eq('"a""b"')
  end

  it "skip null values" do
    expect({ "a" => nil }.to_jsv).to eq("{}")
    expect([nil].to_jsv).to eq("[]")
  end

  it "converts symbols like strings" do
    expect({ a: :b }.to_jsv).to eq("{a:b}")
  end

  it "converts booleans" do
    expect(true.to_jsv).to eq("True")
    expect(false.to_jsv).to eq("False")
  end

  it "converts numbers" do
    expect(1.to_jsv).to eq(1)
    expect(3.14.to_jsv).to eq(3.14)
  end

  it "converts nested structures" do
    expect({ "a" => { "b" => "c" } }.to_jsv).to eq("{a:{b:c}}")
    expect({ "a" => ["b", "c"] }.to_jsv).to eq("{a:[b,c]}")
  end

  it "converts relastic structures" do
    hash = {
      Type: :TransactionalService,
      "Contact": {
        "FieldList": [
          {
            "ID": 3,
            "Value": "glou[0]"
          }
        ]
      },
      "Message": {
        "Subject": "You, and me",
        "ForceHttp": true,
        "IsTrackingValidated": false,
        "IgnoreMe": nil,
        "SourceCode":  "<html><body><p>Un mail tout simple pour commencer</p></body></html>",
        "SourceWithQuote": 'Ceci est une double quote: "'
      }
    }

    expected = '{Type:TransactionalService,Contact:{FieldList:[{ID:3,Value:"glou[0]"}]},Message:{Subject:"You, and me",ForceHttp:True,IsTrackingValidated:False,SourceCode:<html><body><p>Un mail tout simple pour commencer</p></body></html>,SourceWithQuote:"Ceci est une double quote: """}}'
    expect(hash.to_jsv).to eq(expected)
  end
end
