require 'docile'

def remediate(&block)
  Docile.dsl_eval(RemediationBuilder.new, &block).build
end

class RemediationBuilder
  def initialize
    @error_handling = true
    @verbose = false
  end

  def without_error_handling!
    @error_handling = false
  end
  
  def verbose!
    @verbose = true
  end

  def each_druid(&block)
    ARGF.each_line do |druid|
      begin
        STDERR.puts("#{druid}") if verbose?
        Docile.dsl_eval(ObjectBuilder.new(druid), &block).build
      rescue => e
        if @error_handling
          STDERR.puts("#{druid}: #{e}")
        else
          raise e
        end
      end
    end
  end

  def verbose?
    @verbose
  end

  def build
  end
end

class ObjectBuilder
  attr_reader :druid

  def initialize(druid)
    @druid = druid
  end
  
  def object
    @object ||= Dor.find(druid)
  end
  
  def bare_druid
    object.remove_druid_prefix
  end
  
  def respond_to_missing?(method, *args)
    object.respond_to? method
  end
  
  def method_missing(method, *args, &block)
    if object.respond_to? method
      object.public_send(method, *args, &block)
    else
      super
    end
  end
  
  def build
  end
end
