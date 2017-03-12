class Crawler::Spider < Crawler::Base
  sidekiq_options queue: :spider,
                  retry: true,
                  backtrace: true,
                  unique: :until_and_while_executing,
                  unique_expiration: 120 * 60

  def perform(url)
    return if url.nil?
    @url = url
    Timeout::timeout(60) do
      parser.page = scraper.get
    end
    internal_links
    upload
    visit.cache unless internal_links.empty?
  rescue Mechanize::ResponseCodeError => e
    if e.response_code == '404' ||
         e.response_code == '410' ||
         e.response_code == '520' ||
         e.response_code == '500' ||
         e.response_code == '301' ||
         e.response_code == '302'
      Recorder::UrlAvailability.perform_async url
    else
      raise
    end
  rescue Mechanize::RedirectLimitReachedError => e
    nil
  rescue Timeout::Error => e
    Crawler::Stretcher.perform_async url
  end
end
