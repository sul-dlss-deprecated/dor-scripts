#!/usr/bin/env ruby
require_relative '../boot.rb'

remediate do
  verbose!
  without_error_handling!

  # Only process records with missing or non-unique resource ids
  condition do |obj|
    ids = obj.contentMetadata.ng_xml.xpath('//resource/@id').map { |id| id.to_s }

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
