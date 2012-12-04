class Path
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations::Callbacks

  validates_format_of :name, with:/^[\/\-\.a-z0-9]*$/i, message: 'must only contain ASCII letters, numbers, . or -'
  validates_inclusion_of :type, :in =>['file', 'directory'], :message => 'must be a file or directory'
  validates_presence_of :name
  validates_numericality_of :rev, only_integer: true, allow_nil: true, greater_than_or_equal_to: 0
 
  def self.default_attributes
    {'name' => nil, 'type' => 'file', 'value' => nil, 'rev' => nil}
  end
 
  def initialize(attributes={})
    @attributes = HashWithIndifferentAccess.new
    self.class.default_attributes.merge(attributes).each do |k,v|
      send('attribute=', k,v)
    end
  end
  
  def update_attributes(attributes={})
    attributes.each {|k,v| send('attribute=', k,v) }
    save
  end
  
  def save
    if valid?
      resp = $doozer.set self.name, value.to_json, (attribute(:rev) || 0)
      errors.add(:name, "already exists") if resp.err_code == Fraggle::Block::Response::Err::REV_MISMATCH
    end
    self
  end
  
  def destroy
    $doozer.del self.name, self.class.current_rev
  end
  
  def self.find(path)
    rev = current_rev
    resp = $doozer.get path, rev
    
    if resp.err_code == Fraggle::Block::Response::Err::ISDIR
      subdirs = []
      while resp.err_code != Fraggle::Block::Response::Err::RANGE
        resp = $doozer.getdir(path, rev, subdirs.length).first
        subdirs << resp.path if resp.path
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
    $doozer.rev.rev
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
    $doozer.walk('/**').map(&:path).each {|p| $doozer.del(p, Path.current_rev) unless p =~ /^\/ctl\// }
  end
  
end

=begin


1.9.3-p286 :028 > $doozer.set('/test/123', 'test', nil)
 => <Fraggle::Block::Response tag: 0, err_code: MISSING_ARG(7)> 
1.9.3-p286 :029 > $doozer.set('/test/123', 'test', 0)
 => <Fraggle::Block::Response tag: 0, rev: 501> 
1.9.3-p286 :030 > $doozer.set('/test/123', 'test', 0)
 => <Fraggle::Block::Response tag: 0, err_code: REV_MISMATCH(5)> 
1.9.3-p286 :031 > $doozer.set('/test/123', 'test', 501)
 => <Fraggle::Block::Response tag: 0, rev: 504> 


=end
