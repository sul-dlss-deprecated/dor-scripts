require 'docile'

def remediate(&block)
  Docile.dsl_eval(RemediationBuilder.new, &block).build
end

# Common remediation task DSL
class RemediationBuilder
  attr_reader :report

  def initialize
    @exception_handling = true
    @report = Struct.new(:error_count, :success_count, :skipped_count).new(0, 0, 0)
    @condition = proc { true }
  end

  def without_exception_handling!
    @exception_handling = false
  end

  def verbose!
    logger.level = Logger::DEBUG
    @verbose = true
  end

  # rubocop:disable Metrics/MethodLength
  def each_druid(&block)
    druids.each_with_index do |druid, i|
      begin
        logger.debug("#{i}: #{druid}")
        obj = ObjectBuilder.new(druid)

        if condition.call(obj)
          Docile.dsl_eval(obj, &block).build
          report.success_count += 1
        else
          report.skipped_count += 1
        end
      rescue => exception
        handle_exception(druid: druid, exception: exception)
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  def condition(&block)
    if block_given?
      @condition = block
    else
      @condition
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
    report
  end

  private

  def logger
    @logger ||= Logger.new(STDERR)
  end

  def handle_exception(druid:, exception:)
    raise exception unless handle_exceptions?

    logger.error("#{druid}: #{e}")
    report.error_count += 1
  end

  def handle_exceptions?
    @exception_handling
  end
end

# Object-specific remediation tasks DSL
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

  def respond_to_missing?(method, *_args)
    object.respond_to? method
  end

  def method_missing(method, *args, &block)
    if object.respond_to? method
      object.public_send(method, *args, &block)
    else
      super
    end
  end

  def build; end
end
