#
## Author:: Joe Williams (j@boundary.com)
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require 'chef/knife'
require 'digest/md5'
 
module KnifeDiff
  class DiffCookbooks < Chef::Knife
    
    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbooks"
    
    def run
      self.config = Chef::Config.merge!(config)
      
      remote_cookbooks = KnifeDiff::build_sorted_remote_cookbook_list(rest)
      
      local_cookbooks = KnifeDiff::build_sorted_local_cookbook_list
      
      local_only = KnifeDiff::diff_lists(local_cookbooks, remote_cookbooks)
      ui.info("Local orphan cookbooks:")
      ui.info(local_only)
      
      remote_only = KnifeDiff::diff_lists(remote_cookbooks, local_cookbooks)
      ui.info("\nRemote orphan cookbooks:")
      ui.info(remote_only)
      
    end
  end
  
  class DiffCookbook < Chef::Knife
    
    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbook COOKBOOK [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all cookbooks (list provided by local repo), rather than just a single cookbook"
        
    def run
      self.config = Chef::Config.merge!(config)
      
      if config[:all]
        remote_cookbooks = KnifeDiff::build_sorted_local_cookbook_list
        
        remote_cookbooks.each do |cookbook|
          KnifeDiff::cookbook_compare(ui, rest, cookbook)
        end
        
      else
        unless name_args.size == 1
          ui.error("Please specify a cookbook!")
          show_usage
          exit 1
        end

        KnifeDiff::cookbook_compare(ui, rest, name_args.first)
      end
    end
  end
  
  # stolen from https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/cookbook_upload.rb#L116  
  def self.cookbook_repo
    @cookbook_loader ||= begin
      Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, Chef::Config[:cookbook_path]) }
      Chef::CookbookLoader.new(Chef::Config[:cookbook_path])
    end
  end
    
  def self.build_sorted_remote_cookbook_list(rest)
    cookbook_list	= rest.get_rest("cookbooks?num_versions=1")

    remote_cookbooks = []
      
    cookbook_list.each do |name, book|
      remote_cookbooks << name
    end
    remote_cookbooks.sort!
  end
    
  def self.build_sorted_local_cookbook_list
    local_cookbooks = []

    cookbook_repo.cookbooks_by_name.each do |name, book|
      local_cookbooks << name
    end
    local_cookbooks.sort!
  end
    
  def self.diff_lists(a, b)
    a - b
  end
  
  def self.get_cookbook(rest, cookbook)
    cookbook_data = rest.get_rest("cookbooks/#{cookbook}")
    rest.get_rest(cookbook_data[cookbook]["versions"][0]["url"])
  end
  
  def self.generate_local_checksums(manifest)
    files = {}
    
    manifest.attribute_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.definition_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end

    manifest.file_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.library_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.metadata_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.provider_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.recipe_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.resource_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.root_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    manifest.template_filenames.each do |file|
      checksum = Digest::MD5.hexdigest(File.read(file))
      files.store(checksum, file)
    end
    
    files
  end
  
  def self.cookbook_file_diff(remote_cookbook, checksums)
    checksum_diff_list = remote_cookbook.checksums.keys.sort - checksums.keys.sort

    list = []

    checksum_diff_list.each do |checksum|
      if checksums[checksum].nil?
        remote_cookbook.manifest_records_by_path.each do |path, value|
          if value["checksum"] == checksum
            list << value["name"]
          end
        end
      else
        list << checksums[checksum]
      end
    end
    
    list
  end
  
  def self.cookbook_compare(ui, rest, cookbook)
    remote_cookbook = KnifeDiff::get_cookbook(rest, cookbook)
    
    local_cookbook_manifest = KnifeDiff::cookbook_repo.cookbooks_by_name[cookbook]
    
    cookbook_checksums = KnifeDiff::generate_local_checksums(local_cookbook_manifest)
    
    list = KnifeDiff::cookbook_file_diff(remote_cookbook, cookbook_checksums)
    
    if list.length > 0
      ui.info("#{cookbook} cookbook files out of sync:")
      ui.info(list)
      ui.info("")
    end
    
  end
end