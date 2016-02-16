class Github::Releases

  def self.latest
    release = Hashie::Mash.new JSON.parse(Github::API.latest_release)
    release.published_at = release.published_at.to_date.strftime('%d/%m/%Y')

    release
  end
end