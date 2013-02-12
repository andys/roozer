class Path
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations::Callbacks

  validates_format_of :name, with:/^[\x20-\x7F]*$/i, message: 'must only contain ASCII printables'
  validates_inclusion_of :type, :in =>['file', 'directory'], :message => 'must be a file or directory'
  validates_presence_of :name
  validates_numericality_of :rev, only_integer: true, allow_nil: true, greater_than_or_equal_to: 0
 
  def self.default_attributes
    {'name' => nil, 'type' => 'file', 'value' => nil, 'rev' => nil}
  end
  
  def self.decode_name(n)
    n.gsub(/\.([0-9A-F]{2})\./) {|match| $1.hex.chr } if n
  end
  
  def encoded_name
    self.class.encode_name(name)
  end
  
  def self.encode_name(n)
    n.gsub(/[^\/0-9A-Z\-]/i) {|match| '.%02X.' % match.ord } if n.respond_to?(:gsub)
  end
 
  def initialize(attributes={})
    @attributes = HashWithIndifferentAccess.new
    self.class.default_attributes.merge(attributes).each {|k,v| send('attribute=',k,v) }
  end
  
  def update_attributes(attributes={})
    attributes.each {|k,v| send('attribute=',k,v) }
    save
  end
  
  def save
    if valid?
      resp = Roozer::Application.doozer.set encoded_name, value.to_json, (attribute(:rev) || 0)
      errors.add(:name, "already exists") if resp.err_code == Fraggle::Block::Response::Err::REV_MISMATCH
    end
    self
  end
  
  def destroy
    Roozer::Application.doozer.del encoded_name, self.class.current_rev
  end
  
  def self.find(path)
    rev = current_rev
    encoded_path = encode_name(path)
    resp = Roozer::Application.doozer.get encoded_path, rev
    
    if resp.err_code == Fraggle::Block::Response::Err::ISDIR
      subdirs = []
      n = 0
      while resp.err_code != Fraggle::Block::Response::Err::RANGE
        resp = Roozer::Application.doozer.getdir(encoded_path, rev, n).first
        subdirs << decode_name(resp.path) if resp.path
        n += 1
      end
      new(name: path, type: 'dir', value: subdirs)
      
    elsif resp.err_code
      raise "Doozer Error Code #{resp.err_code}"
      
    elsif resp.rev == 0 && resp.value.blank?
      raise ActiveRecord::RecordNotFound.new('Path not found')
      
    else
      new(name: path, type: 'file', value: JSON.parse_any(resp.value), rev: resp.rev)
    end
  end

  def self.err_code(response)
    response.err_code && response.name_for(Fraggle::Block::Response::Err, response.err_code)
  end
  
  def self.current_rev
    Roozer::Application.doozer.rev.rev
  end

  attribute_method_suffix '='

  def attributes
    @attributes
  end

  def attribute(k)
    @attributes[k.to_s]
  end
  
  def attribute=(k,v)
    @attributes[k.to_s] = v if self.class.default_attributes.has_key? k.to_s
  end

  alias :read_attribute_for_validation :attribute
  alias :read_attribute_for_serialization :attribute

  def self.create(*args)
    self.new(*args).save
  end
  
  def self.delete_all!
    Roozer::Application.doozer.walk('/**').map(&:path).each {|p| Roozer::Application.doozer.del(p, Path.current_rev) unless p =~ /^\/ctl\// }
  end
  
  def as_json(opts={})
    super({root: false}.merge(opts))
  end
  
end
