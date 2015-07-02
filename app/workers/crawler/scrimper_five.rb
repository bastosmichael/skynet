class Crawler::ScrimperFive < Crawler::Base
  sidekiq_options queue: :scrimper_five,
                  retry: true,
                  backtrace: true,
                  unique: true,
                  unique_job_expiration: 24 * 60

  def perform(url)
    @url = url
    parser.page = scraper.get
    upload
  rescue Mechanize::ResponseCodeError => e
    if e.response_code == '404' || e.response_code == '520'
      Recorder::Deleter.perform_async url
    else
      raise
    end
  rescue Net::HTTP::Persistent::Error => e
    Crawler::ScrimperFive.perform_async @url
  rescue Mechanize::RedirectLimitReachedError => e
    nil
  end
end