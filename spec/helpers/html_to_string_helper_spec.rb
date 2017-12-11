describe HtmlToStringHelper do
  describe "#html_to_string" do
    describe 'does not change plain text' do
      it { expect(helper.html_to_string('text')).to eq('text') }
    end

    describe 'deals with <br>' do
      it { expect(helper.html_to_string('new<br>line')).to eq("new\nline") }
      it { expect(helper.html_to_string('new<br/>line')).to eq("new\nline") }
      it { expect(helper.html_to_string('new<br />line')).to eq("new\nline") }
    end

    describe 'deals with <p>' do
      it { expect(helper.html_to_string('<p>p1</p><p>p2</p>')).to eq("p1\np2\n") }
    end

    describe 'strip other tags' do
      it { expect(helper.html_to_string('<i>italic</i>')).to eq('italic') }
    end
  end
end
