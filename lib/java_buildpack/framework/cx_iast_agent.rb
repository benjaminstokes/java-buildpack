    
# frozen_string_literal: true

# Cloud Foundry Java Buildpack
# Copyright 2013-2019 the original author or authors.
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

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/logging/logger_factory'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework
  
    class CxIastAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger CxIastAgent
        super(context)        
      end

      def detect
        @logger.debug("CxIast detect running")
        @application.services.one_service? FILTER, 'iast_server'
      end

      def compile
        agent_url = credentials = @application.services.find_service(FILTER, 'iast_server')['credentials']['iast_server'] + "/iast/compilation/download/JAVA"
        @uri = agent_url # overriding the @uri from to download the agent from the user's own CxIAST server
        @logger.debug("Downloading agent from " + agent_url)

        JavaBuildpack::Util::Cache::InternetAvailability.instance.available(
          true, 'The Checkmarx IAST Agent download location is always accessible'
        ) do
          @logger.debug("Downloading agent w/ internet available")
          download_zip
          @logger.debug("Finished downloading agent w/ internet available")
        end
      end
        
      def release
        @logger.debug("CxIast release running - Configuring CxIAST Agent")
        @droplet.java_opts.add_system_property('cxAppTag', @application.details['application_name'])
        @droplet.java_opts.add_system_property('cxTeam', 'CxServer')
        @droplet.java_opts.add_system_property('iast.home', '/home/vcap/app/.java-buildpack/cx_iast_agent')
        @droplet.java_opts.add_preformatted_options("-Xverify:none")   
        @droplet.java_opts.add_javaagent(@droplet.sandbox + 'cx-launcher.jar') 

        credentials = @application.services.find_service(FILTER, 'iast_server')['credentials']
        @logger.debug("CxIast agent uri is: " + credentials['iast_server'])

        write_configuration credentials
      end

      protected

      def supports?
        @application.services.one_service? FILTER, 'iast_server'
      end
      
      private
      
      FILTER = /checkmarx/.freeze

      private_constant :FILTER

      def iastprops
        @droplet.sandbox + 'cx_agent.override.properties'
      end

      def write_configuration(credentials)
        iastprops.open(File::APPEND | File::WRONLY) do |f|
          f.write ("cxIastServer="+  credentials['iast_server'])
          f.write ("\n")

          credentials.each do |key, value|
            f.write ("#{key}=#{value}")
            f.write ("\n")
          end
        end
      end
      
    end
  end
end