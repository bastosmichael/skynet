class Syncer::Reslider < Syncer::Base
  def perform(container)
    @container = container
    records.with_progress("Reslide Crawling #{container}").each do |r|
      Crawler::Slider.perform_async record(r.key.gsub('.json','')).try(:url)
    end
  end
end
