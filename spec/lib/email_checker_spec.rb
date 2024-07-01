describe EmailChecker do
  describe 'check' do
    subject { described_class }

    it 'works with identified use cases' do
      expect(subject.check(email: nil)).to eq({ success: false })
      expect(subject.check(email: '')).to eq({ success: false })
      expect(subject.check(email: 'panpan')).to eq({ success: false })

      # allow same domain
      expect(subject.check(email: "martin@orange.fr")).to eq({ success: true })
      # find difference of 1 lev distance
      expect(subject.check(email: "martin@orane.fr")).to eq({ success: true, suggestions: ['martin@orange.fr'] })
      # find difference of 2 lev distance, only with same chars
      expect(subject.check(email: "martin@oragne.fr")).to eq({ success: true, suggestions: ['martin@orange.fr'] })
      # ignore unknown domain
      expect(subject.check(email: "martin@ore.fr")).to eq({ success: true })
    end

    it 'passes through real use cases, with levenshtein_distance 1' do
      expect(subject.check(email: "martin@asn.com")).to eq({ success: true, suggestions: ['martin@msn.com'] })
      expect(subject.check(email: "martin@gamail.com")).to eq({ success: true, suggestions: ['martin@gmail.com'] })
      expect(subject.check(email: "martin@glail.com")).to eq({ success: true, suggestions: ['martin@gmail.com'] })
      expect(subject.check(email: "martin@gmail.coml")).to eq({ success: true, suggestions: ['martin@gmail.com'] })
      expect(subject.check(email: "martin@gmail.con")).to eq({ success: true, suggestions: ['martin@gmail.com'] })
      expect(subject.check(email: "martin@hotmil.fr")).to eq({ success: true, suggestions: ['martin@hotmail.fr'] })
      expect(subject.check(email: "martin@mail.com")).to eq({ success: true, suggestions: ["martin@gmail.com", "martin@ymail.com", "martin@mailo.com"] })
      expect(subject.check(email: "martin@msc.com")).to eq({ success: true, suggestions: ["martin@msn.com", "martin@mac.com"] })
      expect(subject.check(email: "martin@ymail.com")).to eq({ success: true })
    end

    it 'passes through real use cases, with levenshtein_distance 2, must share all chars' do
      expect(subject.check(email: "martin@oise.fr")).to eq({ success: true }) # could be live.fr
    end
  end
end
