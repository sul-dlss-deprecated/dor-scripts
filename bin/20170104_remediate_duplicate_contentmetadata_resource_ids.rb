#!/usr/bin/env ruby
require_relative '../boot.rb'

remediate do
  verbose!
  without_error_handling!

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
