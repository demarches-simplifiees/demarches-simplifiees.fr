class Github::Releases

  def self.latest
    release = Hashie::Mash.new JSON.parse(Github::API.latest_release)

    return nil if release.nil?

    release.published_at = release.published_at.to_date.strftime('%d/%m/%Y')
    release
  end
end