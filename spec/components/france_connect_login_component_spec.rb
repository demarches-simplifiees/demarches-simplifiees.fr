describe FranceConnectLoginComponent, type: :component do
  it "renders url" do
    expect(
      render_inline(described_class.new(url: "/hello")).css(".france-connect-login-buttons").to_html
    ).to include("/hello")
  end
end
