    
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

require 'java_buildpack/component/base_component'
require 'java_buildpack/logging/logger_factory'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework
  
    # Encapsulates the functionality for contributing AspectJ Runtime Weaving configuration an application.
    class CxIastAgent < JavaBuildpack::Component::BaseComponent

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        super(context)
        @logger = JavaBuildpack::Logging::LoggerFactory.instance.get_logger CxIastAgent
      end

      def detect
        @logger.debug("CxIast detect running")
        @droplet

      end

      def compile 
        @logger.debug("CxIast compile running - Downloading CxIAST Agent")
        download_zip(3, 'http://iast30.cx.sekots.org:8380/iast/compilation/download/JAVA', false)
        @droplet.copy_resources

      end

      def release
        @logger.debug("CxIast release running - Configuring CxIAST Agent")
        @droplet.java_opts.add_system_property('cxAppTag', @application.details['application_name'])
        #@droplet.java_opts.add_system_property('cxScanTag', application_name)
        @droplet.java_opts.add_system_property('cxTeam', 'CxServer')

        @droplet.java_opts.add_system_property('iast.home', '/home/vcap/app/.java-buildpack/cx-iast-agent')
        
        @droplet.java_opts.add_preformatted_options("-Xverify:none")   

        @droplet.java_opts.add_javaagent('/home/vcap/app/.java-buildpack/cx-iast-agent/cx-launcher.jar')     

      end
    end
  end
end