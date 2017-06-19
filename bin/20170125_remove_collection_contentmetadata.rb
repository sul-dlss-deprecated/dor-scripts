#!/usr/bin/env ruby
require_relative '../boot.rb'

OptionParser.new do |opts|
  opts.banner = <<-EOB
    Usage: 20170104_remove_collection_contentmetadata.rb [FILE...]"

    One-off script to remediate DOR objects where collection resources
    have a stub contentMetadata datastream.
  EOB

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

remediate do
  verbose!

  # Only process records with missing or non-unique resource ids
  condition do |obj|
    obj.datastreams['hydrusProperties'] &&
      !obj.datastreams['contentMetadata'].nil? &&
      Nokogiri::XML(obj.datastreams['contentMetadata'].content.to_s).root.children.length.zero?
  end

  each_druid do
    with_versioning significance: :admin, description: 'Remove stub content metadata' do
      datastreams['contentMetadata'].delete
    end
  end

  puts report.inspect
end
