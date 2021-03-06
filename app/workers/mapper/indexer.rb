class Mapper::Indexer < Mapper::Base
  def perform(container, id, hash = nil)
    @container = container
    types = container.split('-').last.pluralize.gsub(':', '')
    hash = record(id).data if hash.nil?
    index = Rails.env + '-' + types
    new_hash = {}

    # hash.each do |k, v|
    hash.each do |k, v|
      unless Record::Upload::EXCLUDE.include? k.to_sym
        if v.is_a?(Hash)
          value = v.values.last

          if value.is_a?(Array) || !!value == value
            new_hash[k] = value
          elsif value.to_i.to_s == value.to_s
            new_hash[k] = value.to_i
          elsif (Float(value) rescue false)
            new_hash[k] = value.to_f
            new_hash[k] = value if new_hash[k].infinite?
          else
            new_hash[k] = value
          end

          new_hash[k + '_history'] = v.count if v.count > 1
        elsif !!v == v # Check if Boolean
          new_hash[k] = v
        elsif v.is_a?(Array)
          new_hash[k] = v.map {|value| value.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''}) }
        else
          new_hash[k] = v.encode(Encoding.find('UTF-8'), {invalid: :replace, undef: :replace, replace: ''})
        end
      end
    end

    # Delete bad keys from search...
    if bad_ids = Elasticsearch::Model.client.search(index: index, type: @container, body: { query: { match_phrase_prefix: { url: new_hash['url'] } } })['hits']['hits'].select do |hit|
                   hit['_id'] != id
                 end
      bad_ids.each do |bad_id|
        record(bad_id['_id']).delete
        Elasticsearch::Model.client.delete index: index, type: @container, id: bad_id['_id']
      end unless bad_ids.empty?
    end

    Elasticsearch::Model.client.index index: index, type: container, id: id, body: new_hash.sort.to_h

    Elasticsearch::Model.client.indices.refresh index: index
  # rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
  # # rescue Elasticsearch::Transport::Transport::Errors::NotFound
  #  record(id).delete
  #  Crawler::Scrimper.perform_async new_hash['url'] if new_hash['url']
  rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
    nil
  end
end
