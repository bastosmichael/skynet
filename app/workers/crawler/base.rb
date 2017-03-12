class Crawler::Base < Worker
  def scraper
    @scraper ||= Crawl::Base.new(@url)
  end

  def parser
    @parser ||= scraper.name.capitalize.constantize.new(@url)
  rescue NameError
    @parser ||= Page::Parse.new(@url)
  end

  def upload
    scraper.clear
    parsed = parser.save if parser.build
    if parsed && parsed['type']
      Recorder::Uploader.perform_async parsed
    end
  end

  def social
    @social ||= Crawl::Social.new(@url)
  rescue
    {}
  end

  def internal_links
    @internal_links ||= begin
      parser.internal_links.map do |url|
        scraper.name.capitalize.constantize.sanitize_url(url)
      end
    rescue
      parser.internal_links
    end
  end

  def visit
    @visit ||= Page::Visit.new(internal_links, self.class.name.split('::').last)
  end
end
