require 'docile'

def remediate(&block)
  Docile.dsl_eval(RemediationBuilder.new, &block).build
end

class RemediationBuilder
  def initialize
    @error_handling = true
  end

  def without_error_handling!
    @error_handling = false
  end

  def verbose!
    logger.level = Logger::DEBUG
    @verbose = true
  end

  def each_druid(&block)
    druids.each_with_index do |druid, i|
      begin
        logger.debug("#{i}: #{druid}")
        Docile.dsl_eval(ObjectBuilder.new(druid), &block).build
      rescue => e
        if @error_handling
          logger.error("#{i}: #{druid}: #{e}")
        else
          raise e
        end
      end
    end
  end

  def druids
    return to_enum(:druids) unless block_given?

    ARGF.each_line do |druid|
      if druid =~ /^druid:/
        yield druid
      else
        yield "druid:#{druid}"
      end
    end
  end

  def verbose?
    @verbose
  end

  def build
  end

  def logger
    @logger ||= Logger.new(STDERR)
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
