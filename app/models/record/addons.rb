class Record::Addons
  def self.insert hash
    if inserts = Rails.configuration.config[:admin][:insert][hash[:container].try(:to_sym)]
      inserts.each do |key, value|
        if hash[key] && key == :url
          hash[key] = value + CGI.escape(hash[key])
        elsif hash[key]
          hash[key] = value + hash[key]
        end
      end
    end
    return hash
  end

  def self.append hash
    if appends = Rails.configuration.config[:admin][:append][hash[:container].try(:to_sym)]
      appends.each do |key, value|
        hash[key] = hash[key] + value if hash[key]
      end
    end
    return hash
  end
end
