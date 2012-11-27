class Path
  include ActiveModel::Validations
  include ActiveModel::Serializers::JSON
  include ActiveModel::AttributeMethods
  include ActiveModel::Validations::Callbacks

  def initialize(attributes={})
    @attributes = HashWithIndifferentAccess.new(name: nil, type: 'file', value: nil).merge(attributes)
  end
  
  def save
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
      raise ActiveRecord::RecordNotFound
    else
      new(name: path, type: 'file', value: resp.value)
    end
  end

  def self.err_code(response)
    response.err_code && response.name_for(Fraggle::Block::Response::Err, response.err_code)
  end
  
  def self.current_rev
    $doozer.rev.rev
  end

  attribute_method_suffix '', '='

  def attributes
    @attributes
  end

  def attribute(k)
    @attributes[k]
  end
  def attribute=(k,v)
    @attributes[k]=v
  end
  def read_attribute_for_validation(k)
    attribute(k)
  end
  def self.create(*args)
    self.new(*args).save
  end
  def update_attributes(attributes={})
    attributes.delete(:id)
    self.attributes.merge!(attributes)
    self.save
  end
  
end

=begin
1.9.3-p286 :004 > $doozer.set('/flibble/foo', '', 103)
 => <Fraggle::Block::Response tag: 0, rev: 105> 
 
=end
