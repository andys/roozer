module JSON
  def self.parse_any(str,opts={})
    parse("[#{str}]",opts).first
  end
end
