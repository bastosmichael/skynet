class Record::Search < Record::Match
  alias_method :search, :best

  def match_query
    cleanup_query
    @query_hash.flat_map do |k, v|
      [{
        match: {
          k => v
        }
      },
      {
        flt_field: {
          k => {
            like_text: v,
            analyzer: 'snowball',
            fuzziness: 0.7
          }
        }
      }]
    end
  end

  def cleanup_query
    if @query_hash[:query]
      @query_hash[:name] = @query_hash[:query]
      @query_hash[:description] = @query_hash[:query]
      @query_hash[:url] = @query_hash[:query]
      @query_hash[:tags] = @query_hash[:query]
      @query_hash[:categories] = @query_hash[:query]
      @query_hash.delete(:query)
    end
  end
end
