# A script for your local system.
#
# Download all of the files listed in the public XML for a given druid
# if no local save location is specified, the current script directory is used
# in either case, a druid folder is created to hold all of the files
#
# Note that you need to be webauthed, have a valid kerberos ticket, be on campus (or VPN)
# and have access to the stacks server (as lyberadmin).
#
# Peter Mangiafico
# Septembert 1, 2015
#
# Run with
#   ruby download_object.rb druid [save_location]
# e.g.
#   ruby download_object.rb oo000oo0001 ~/Desktop

require 'open-uri'
require File.expand_path(File.dirname(__FILE__) + '/../boot')

def help(error_msg)
  abort "#{error_msg}\n\nUsage:\n    download_object DRUID [SAVE_LOCATION]\n"
end

# Load YAML config file for the bundle of materials to be pre-assembled.
help "Incorrect N of arguments." if ARGV.empty?
druid = ARGV[0]
druid = druid.downcase.gsub('druid:', '')
base_output_path = ARGV[1] || __dir__
output_path = File.join(base_output_path, druid)

puts "Downloading #{druid} to #{output_path}"

FileUtils.mkdir_p output_path

response = RestClient.get "http://purl.stanford.edu/#{druid}.xml"
ng = Nokogiri::XML(response)

files = ng.css('//contentMetadata/resource/file')

files.each do |file|
  filename = File.join(output_path, file['id'])
  stacks_path = File.join(Assembly::Utils.get_staging_path(druid, '/stacks'), file['id'])
  puts "...downloading #{filename}"
  copy_command = "rsync -vOlt lyberadmin@stacks.stanford.edu:#{stacks_path} #{filename}"
  `#{copy_command}`
end

puts "Done"
