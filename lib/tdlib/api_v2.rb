require "fast_jsonparser"
require "ffi"

module TD::ApiV2
  module_function

  def create_client
    Dl.td_create_client_id
  end

  def client_send(client_id, params)
    Dl.td_send(client_id, params.to_json)
  end

  def client_receive(timeout)
    sleep 0.002
    update = Dl.td_receive(timeout)
    FastJsonparser.parse(update, symbolize_keys: false) if update
  end

  def client_execute(params)
    update = Dl.td_execute(params.to_json)
    FastJsonparser.parse(update, symbolize_keys: false) if update
  end

  def set_log_verbosity_level(level)
    Dl.td_set_log_verbosity_level(level)
  end

  def set_log_file_path(path)
    Dl.td_set_log_file_path(path)
  end


  module Dl
    extend FFI::Library

    @mutex = Mutex.new

    module_function

    def method_missing(method_name, *args)
      @mutex.synchronize do
        return public_send(method_name, *args) if respond_to?(method_name)

        find_lib

        attach_function :td_create_client_id, [], :int
        attach_function :td_receive, [:double], :string, blocking: true
        attach_function :td_send, [:int, :string], :void
        attach_function :td_execute, [:string], :string
        attach_function :td_set_log_file_path, [:string], :int
        attach_function :td_set_log_max_file_size, [:long_long], :void
        attach_function :td_set_log_verbosity_level, [:int], :void

        undef method_missing
        public_send(method_name, *args)
      end
    end

    def find_lib
      file_name = "libtdjson.#{lib_extension}"
      lib_path =
        if TD.config.lib_path
          TD.config.lib_path
        elsif defined?(Rails) && File.exist?(Rails.root.join("vendor", file_name))
          Rails.root.join("vendor")
        end
      full_path = File.join(lib_path.to_s, file_name)
      ffi_lib full_path
      full_path
    rescue LoadError
      ffi_lib "tdjson"
      ffi_libraries.first.name
    end

    def lib_extension
      case os
      when :windows then "dll"
      when :macos then "dylib"
      when :linux then "so"
      else raise "#{os} OS is not supported"
      end
    end

    def os
      host_os = RbConfig::CONFIG["host_os"]
      case host_os
      when %r{mswin|msys|mingw|cygwin|bccwin|wince|emc}
        :windows
      when %r{darwin|mac os}
        :macos
      when %r{linux}
        :linux
      when %r{solaris|bsd}
        :unix
      else
        raise "Unknown os: #{host_os.inspect}"
      end
    end
  end
end
