# Encoding: utf-8
# IBM WebSphere Application Server Liberty Buildpack
# Copyright 2014 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require 'liberty_buildpack/diagnostics/logger_factory'
require 'liberty_buildpack/framework'
require 'liberty_buildpack/repository/configured_item'
require 'liberty_buildpack/util/download'
require 'liberty_buildpack/container/common_paths'

module LibertyBuildpack::Framework

  # Provides the required detect/compile/release functionality in order to use JRebel with an application
  class JRebelAgent

    # Creates an instance, passing in a context of information available to the component
    #
    # @param [Hash] context the context that is provided to the instance
    # @option context [String] :app_dir the directory that the application exists in
    # @option context [Hash] :configuration the properties provided by the user
    # @option context [CommonPaths] :common_paths the set of paths common across components that components should reference
    # @option context [Hash] :vcap_application the application information provided by cf
    # @option context [Hash] :vcap_services the services bound to the application provided by cf
    # @option context [Array<String>] :java_opts an array that Java options can be added to
    def initialize(context = {})
      @logger = LibertyBuildpack::Diagnostics::LoggerFactory.get_logger
      @app_dir = context[:app_dir]
      @configuration = context[:configuration]
      @common_paths = context[:common_paths] || LibertyBuildpack::Container::CommonPaths.new
      @vcap_application = context[:vcap_application]
      @java_opts = context[:java_opts]

      puts "JRebelAgent: initialize, appdir: #{@app_dir}, configuration: #{@configuration}"
    end

    def detect
      if File.exists?("#{@app_dir}/WEB-INF/classes/rebel-remote.xml")
        puts 'JRebelAgent: detect, rebel-remote.xml found'
        'jrebel-6.0.2'
      else
        puts 'JRebelAgent: detect, rebel-remote.xml not found'
        nil
      end
    end

    def compile
      puts 'JRebelAgent: compile'

      jr_home = File.join(@app_dir, JR_HOME_DIR)
      FileUtils.mkdir_p(jr_home)

      url = @configuration['download_url']
      puts "JRebelAgent: download_url=#{url}"

      download_agent('6.0.2-SNAPSHOT', url, 'jrebel.jar', jr_home)
    end

    def release
      puts 'JRebelAgent: release'

      jr_home = File.join(@app_dir, JR_HOME_DIR)
      jr_agent = File.join(jr_home, 'jrebel.jar')

      # We specify a log file path, but do not enable logging, the client can do it at his discretion
      jr_log = File.join(jr_home, 'jrebel.log')

      @java_opts << "-javaagent:#{jr_agent}"
      @java_opts << '-Drebel.remoting_plugin=true'
      @java_opts << "-Drebel.log.file=#{jr_log}"
    end

    private

    JR_HOME_DIR = '.jrebel'.freeze

    def download_agent(version_desc, uri_source, target_jar_name, target_dir)
      LibertyBuildpack::Util.download(version_desc, uri_source, target_jar_name, target_jar_name, target_dir)
    rescue => e
      raise "Unable to download the JRebel Agent jar. Ensure that the agent jar at #{uri_source} is available and accessible. #{e.message}"
    end
  end
end

