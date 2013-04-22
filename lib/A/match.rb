# match.rb: Wildcard matching

module Match
  def self.match(template, tomatch, ignorecase)
    # Transform to regex, then apply
    return Regexp.new("^#{Regexp.escape(template).gsub('\*','.*?').gsub('\?', '.?')}$", ignorecase) =~ tomatch
  end
end

