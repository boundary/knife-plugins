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

module BoundaryKnifePlugins
  module Common
    
    # stolen from https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/cookbook_upload.rb#L116  
    def cookbook_repo
      @cookbook_loader ||= begin
        Chef::Cookbook::FileVendor.on_create { |manifest| Chef::Cookbook::FileSystemFileVendor.new(manifest, Chef::Config[:cookbook_path]) }
        Chef::CookbookLoader.new(Chef::Config[:cookbook_path])
      end
    end

    def build_sorted_remote_cookbook_list(rest)
      cookbook_list	= rest.get_rest("cookbooks?num_versions=1")

      remote_cookbooks = []

      cookbook_list.each do |name, book|
        remote_cookbooks << name
      end
      remote_cookbooks.sort!
    end

    def build_sorted_local_cookbook_list
      local_cookbooks = []

      cookbook_repo.cookbooks_by_name.each do |name, book|
        local_cookbooks << name
      end
      local_cookbooks.sort!
    end

    def diff_lists(a, b)
      a - b
    end

    def get_cookbook(rest, cookbook)
      cookbook_data = rest.get_rest("cookbooks/#{cookbook}")
      rest.get_rest(cookbook_data[cookbook]["versions"][0]["url"])
    end

    def generate_local_checksums(manifest)
      files = {}
      %w/attribute definition file library metadata provider recipe resource root template/.each do |resource|
        eval("manifest.#{resource}_filenames").each do |file|
          files.store(Digest::MD5.hexdigest(File.read(file)), file)
        end
      end
      files
    end

    def cookbook_file_diff(remote_cookbook, checksums)
      remote_checksum_diff = remote_cookbook.checksums.keys.sort - checksums.keys.sort
      local_checksum_diff = checksums.keys.sort -  remote_cookbook.checksums.keys.sort 
   
      list = []

      remote_checksum_diff.each do |checksum|
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

      local_checksum_diff.each do |checksum|
        list << "#{checksums[checksum]} - Local Only"
      end if remote_checksum_diff.empty?

      list
    end

    def cookbook_compare(ui, rest, cookbook)
      remote_cookbook = get_cookbook(rest, cookbook)

      local_cookbook_manifest = cookbook_repo.cookbooks_by_name[cookbook]

      cookbook_checksums = generate_local_checksums(local_cookbook_manifest)

      list = cookbook_file_diff(remote_cookbook, cookbook_checksums)

      if list.length > 0
        ui.info("#{cookbook} cookbook files out of sync:")
        ui.info(list)
        ui.info("")
      end

    end

    def get_sorted_local_databags(path)
      local_dbags = Dir.entries(path)
      local_dbags.delete(".")
      local_dbags.delete("..")
      local_dbags.delete("README.md")
      local_dbags.delete("databags")

      local_dbags.sort
    end

    def get_sorted_local_databag_items(path)
      local_dbag_items = Dir.entries(path)
      local_dbag_items.delete(".")
      local_dbag_items.delete("..")

      clean_local_dbag_items = []

      local_dbag_items.each do |item|
        if item.include?(".json")
          clean_local_dbag_items << item.gsub(".json", "")
        elsif item.include?(".rb")
          clean_local_dbag_items << item.gsub(".rb", "")
        end
      end

      clean_local_dbag_items.sort
    end

    def get_sorted_remote_databag_items(databag)
      Chef::DataBag.load(databag).keys.sort
    end

    def compare_databag_item_lists(ui, path, databag)
      remote_dbag_items = get_sorted_remote_databag_items(databag)
      local_dbag_items = get_sorted_local_databag_items("#{path}/#{databag}")

      ui.info("#{databag} local orphan databag items:")
      ui.info(local_dbag_items.sort - remote_dbag_items)

      ui.info("\n#{databag} remote orphan databag items:")
      ui.info(remote_dbag_items - local_dbag_items.sort)
      ui.info("")
    end

    def compare_databag_items(ui, path, databag)
      remote_dbag_items = get_sorted_remote_databag_items(databag)
      local_dbag_items = get_sorted_local_databag_items("#{path}/#{databag}")

      remote_checksums = {}
      local_checksums = {}

      remote_dbag_items.each do |item|
        remote_checksums.store(Digest::MD5.hexdigest(Chef::DataBagItem.load(databag, item).raw_data.to_json), item)
      end

      local_dbag_items.each do |item|
        file = "#{path}/#{databag}/#{item}.json"
        md5 = get_local_file_md5(file)
        local_checksums.store(md5, item)
      end

      checksum_diff_list = remote_checksums.keys.sort - local_checksums.keys.sort

      list = []

      checksum_diff_list.each do |checksum|
        if remote_checksums[checksum].nil?
          list << local_checksums[checksum]
        else
          list << remote_checksums[checksum]
        end
      end

      ui.info("#{databag} databag items out of sync:")
      ui.info(list)
      ui.info("")
    end

    def get_local_file_md5(path)
      Digest::MD5.hexdigest(File.read(path))
    end

    def get_local_json_file_md5(path)
      data = JSON.parse(File.read(path)).to_json # this is gross but works
      Digest::MD5.hexdigest(data)
    end
    
    def find_files(ui, manifest, text)
      ui.info("\n#{manifest["name"]}:")
      manifest.each do |k, v|
        if v.kind_of?(Array)
          v.each do |thing|
            if thing["path"]
              if thing["path"].include?(text)
                ui.info("* #{thing["path"]}")
              end
            end
          end
        end
      end
    end
    
  end
end