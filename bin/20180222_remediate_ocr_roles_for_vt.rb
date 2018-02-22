#!/usr/bin/env ruby
require_relative '../boot.rb'

OptionParser.new do |opts|
  opts.banner = <<-EOB
    Usage: 20180222_remediate_ocr_roles_for_vt.rb [FILE...]"

    One-off script to remediate DOR objects to indicate the presence of OCR content
  EOB

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

remediate do
  verbose!

  with_druids do
    Dor::SearchService.query('is_member_of_collection_ssim:"info:fedora/druid:kh392jb5994"', fl: 'id', rows: 500)['response']['docs'].map { |x| x['id'] }
  end

  # Only process records with PDF content
  condition do |obj|
    obj.datastreams['contentMetadata'] &&
      Nokogiri::XML(obj.datastreams['contentMetadata'].content.to_s).root.xpath('//file[@mimetype="application/pdf"]').any?
  end

  each_druid do
    with_versioning significance: :admin, description: 'Add role="transcription" to ALTO XML' do
      contentMetadata.ng_xml_will_change!
      contentMetadata.ng_xml.xpath('//resource[@type="page"]/file[@mimetype="application/xml"]').each do |r|
        r['role'] = 'transcription'
      end

      save!
    end
  end

  puts report.inspect
end
