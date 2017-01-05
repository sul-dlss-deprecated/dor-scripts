#!/usr/bin/env ruby
require_relative '../boot.rb'

args = Struct.new(:tag).new

OptionParser.new do |opts|
  opts.banner = "Usage: decommision.rb [options] [FILE]"

  opts.on('-tTAG', '--tag=TAG', 'Decommission tag') do |t|
    args.tag = t
  end

  opts.on("-h", "--help", "Prints this help") do
    puts opts
    exit
  end
end.parse!

remediate do
  each_druid do
    decommission(args.tag)
    save
    
    Dor::DigitalStacksService.prune_stacks_dir druid
    publish_metadata
    Dor::CleanupService.cleanup_by_druid druid
    Dor::WorkflowService.archive_active_workflow 'dor', druid
  end
end
