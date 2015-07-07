class Crawler::Socializer < Crawler::Base
  sidekiq_options queue: :socializer,
                  retry: true,
                  backtrace: true,
                  unique: true,
                  unique_job_expiration: 24 * 60

  def perform(url)
    @url = url
    parser.page = scraper.get
    upload
  rescue Net::HTTP::Persistent::Error => e
    Crawler::Socializer.perform_async @url
  rescue Mechanize::RedirectLimitReachedError => e
    nil
  end

  def upload
    parsed = parser.save if parser.build
    if parsed && parsed['type']
      Recorder::Uploader.perform_async parsed.merge(social.shares)
    end
  end
end
