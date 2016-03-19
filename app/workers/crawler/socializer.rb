class Crawler::Socializer < Crawler::Sampler
  sidekiq_options queue: :socializer,
                  retry: true,
                  backtrace: true,
                  unique: :until_and_while_executing,
                  unique_expiration: 120 * 60

  def upload
    parsed = parser.save if parser.build
    if parsed && parsed['type']
      Recorder::Uploader.perform_async parsed.merge(social.shares)
    end
  end
end
