#!/usr/bin/env ruby
require_relative '../boot.rb'

OptionParser.new do |opts|
  opts.banner = <<-EOB
    Usage: 20170104_remediate_duplicate_contentmetadata_resource_ids.rb [FILE...]"

    One-off script to remediate DOR objects where the resource identifiers in
    the contentMetadata are not unique, e.g.:

    <contentMetadata>
      <resource id="manuscript" ... />
      <resource id="manuscript" ... />
      <resource id="manuscript" ... />
    </contentMetadata>
  EOB

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

remediate do
  verbose!
  without_exception_handling!

  # Only process records with missing or non-unique resource ids
  condition do |obj|
    ids = obj.contentMetadata.ng_xml.xpath('//resource/@id').map(&:to_s)

    ids.any? { |id| id.nil? || id.empty? } || ids.length != ids.uniq.length
  end

  each_druid do
    open_new_version

    contentMetadata.ng_xml_will_change!
    contentMetadata.ng_xml.xpath('//resource').each_with_index do |r, i|
      r.attributes['id'].value = "#{bare_druid}_#{i + 1}"
    end

    save!
    close_version
  end

  puts report.inspect
end
