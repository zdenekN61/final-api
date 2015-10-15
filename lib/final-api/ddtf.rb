module FinalAPI
  module DDTF
    PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

    # Mostly scrubed from travis-build
    def config_vars_hash
      line = config[:env].to_s
      secure = line =~ /^SECURE /
      vars = {}
      line.scan(PATTERN).map { |var| vars[var[0]] = var[3] || var[1] }
      vars
    end
  end
end
