# !/usr/bin/env ruby

# Google Books Accessioning Test Script
# used to evaluate performance of our accessioning pipeline
# can be used a guideline for actual ETL
# May 2019

# run with
# ENV=production ruby devel/google_books_accession.rb

require File.expand_path(File.dirname(__FILE__) + '/../boot')

require 'csv'
require 'druid-tools'
require 'fileutils'
require 'rest-client'

# LIKELY MISSING STEPS
# TODO get publication data from google supplied metadata or from our our catalog
# TODO set embargo metadata datastream correctly given publication date
# TODO select correct APO/collection based on publication date (world vs none access)
# TODO what to do about folders that do not look like barcodes?
# TODO create any other derivative files needed (e.g. combined OCR .txt file)
###############################
## CONFIG
# location of google books
content_location = '/dor/content/GoogleBooks/'
#
# limit to number of books accessioned (set to a really big number for no effective limit)
limit = 1000
#
# location to stage the content for accessioning
staging_location = '/dor/assembly/'
#
# set the APO used for here - this is google books citation only (stage)
apo_druid = 'druid:ss315jy0876'
#
# set the collection druid here - this is google books citation only (stage)
collection_druid = 'druid:rr383zg4828'
#
# set the filename for our progress logfile here
progress_log_file = 'google-books.log'
#
# set the workflow to be initiated for the objects here
workflow_name = 'assemblyWF'
#
# barcodes (folder names) must be at least this long
min_barcode_size = 14
#
# default publish/preserve/shelve attributes by mimetype
#   NOTE: this does not publish or shelve .xml or .md5 files
publish_attr = {
  'image/jp2' => {
    publish:            'yes',
    shelve:             'yes',
    preserve:           'yes',
  },
  'image/tiff' => {
    publish:            'no',
    shelve:             'no',
    preserve:           'yes',
  },
  'application/xml' => {
    publish:            'no',
    shelve:             'no',
    preserve:           'yes',
  },
  'default' => {
    publish:             'no',
    shelve:              'no',
    preserve:            'yes',
  }
}
#
# dor-services endpoint for looking up catkey (note: dor-services-client does not support this endpoint yet, see https://github.com/sul-dlss/dor-services-client/issues/45)
catkey_lookup_url = 'https://dorAdmin:dorAdmin@dor-services-stage.stanford.edu/v1/catalog/catkey'
#
################################

start_time = Time.now
puts "Started at #{start_time}.  Content directory: #{content_location}"

num_success = 0
num_error = 0
num_skipped = 0

# iterate over all folders in content location
objects = Dir.glob("#{content_location}*")
num_objects = objects.size

# if progress file exists already, read in already completed druids, else create the file
if File.exist? progress_log_file
  existing_log_file = CSV.read(progress_log_file, headers: true)
  completed_folders = existing_log_file.map {|row| row['folder'] if row['success'] == 'true'}
else
  CSV.open(progress_log_file, 'w', :write_headers=> true, :headers => ['folder','druid','time','success'])
  completed_folders = []
end

# open progress log file
CSV.open(progress_log_file, 'a+') do |csv|

  # now iterate over all folders
  objects.each_with_index do |object, i|

    folder_name = object.gsub(content_location,'').strip # the folder name is the barcode

    # skip things that are not folders or are already accecssioned
    if completed_folders.include?(folder_name) || !File.directory?(object)
      puts "**skipping #{folder_name}"
      num_skipped += 1
      next
    end

    # beginning of rescue guarded workflow for each object
    begin
      puts "#{i} of #{num_objects}: Working on #{folder_name}"

      # confirm our folder looks like a barcode
      if folder_name.size < min_barcode_size
        puts "*** skipping #{folder_name} which does not appear to be a barcode"
        num_skipped += 1
        next
      end

      # get a druid
      pid = Dor::SuriService.mint_id
      puts "...obtained #{pid}"

      # lookup catkey given barcode
      response = RestClient.get "#{catkey_lookup_url}?barcode=#{folder_name}"
      catkey = (response.code == 200 ? response.body.strip : '')

      # register fedora object
      other_ids = { barcode: folder_name }
      other_ids.merge!({ catkey: catkey }) unless catkey.blank?
      registration_params = {
        :object_type     => 'item',
        :admin_policy    => apo_druid,
        :source_id       => { google: "Stanford_#{folder_name}" },
        :pid             => pid,
        :other_ids       => other_ids,
        :metadata_source => 'symphony',
        :label           => ':auto',
        :collection      => collection_druid,
        :tags            => ["Project : Google Books", "Google Book : Scan source STANFORD"],
      }
      item = Dor::RegistrationService.register_object registration_params
      puts "...registered #{pid}"

      # create druid tree folder in staging area and then symlink in all content
      druid_tree_folder = DruidTools::Druid.new(pid,staging_location).path()
      content_dir = File.join(druid_tree_folder,'content')
      metadata_dir = File.join(druid_tree_folder,'metadata')
      FileUtils.mkdir_p content_dir
      FileUtils.mkdir_p metadata_dir
      object_files = Dir.glob("#{object}/*").sort # get all of the files in the source google books folder, and put XML and .md5 at the end
      object_files.each do |source_file| # symlink to the staging area content folder
        destination_file = File.join(content_dir, File.basename(source_file))
        FileUtils.ln_s(source_file, destination_file, :force => true)
      end
      puts "...staged all content"

      # create contentMetadata
      content_object_files = object_files.map {|source_file| Assembly::ObjectFile.new(source_file)}
      cm_params = {druid: pid, objects: content_object_files, file_attributes: publish_attr, add_file_attributes: true, add_exif: false, bundle: :filename, style: :simple_book }
      content_md_xml = Assembly::ContentMetadata.create_content_metadata(cm_params)
      content_metadata_file_name = File.join(metadata_dir, 'contentMetadata.xml')
      File.open(content_metadata_file_name, 'w') { |fh| fh.puts content_md_xml }
      puts "...created contentMetadata"

      # start workflow
      puts "...started #{workflow_name}"
      Dor::Services::Client.object(pid).workflow.create(wf_name: workflow_name)
      num_success += 1

      csv << [folder_name, pid , Time.now, true]

    rescue StandardError => e

      puts "...ERROR OCCURRED: #{e.message}"
      num_error += 1

      csv << [folder_name, pid , Time.now, false]

    end # rescue clause

    # stop iterating if we've hit our limit
    break if num_success >= limit

  end # loop over all folders

end # csv file

end_time = Time.now
total_time = end_time - start_time
time_per_object = total_time / num_success

puts "Ended at: #{end_time}. Total time (minutes): #{(total_time.round)/60}.  Time per object (seconds): #{time_per_object.round(1)}"
puts "Limit: #{limit}. Total success: #{num_success}.  Total skipped: #{num_skipped}. Total error: #{num_error}"
