module FinalAPI
  module DDTF
    PATTERN = /(?:SECURE )?([\w]+)=(("|')(.*?)(\3)|\$\(.*?\)|[^"' ]+)/

    # Mostly scrubed from travis-build
    def config_vars_hash
      line = config[:env].to_s
      secure = line =~ /^SECURE /
      vars = line.scan(PATTERN).map { |var| var[0, 2] }
      vars = vars.each_with_object({}) { |i, o| o[i[0]] = i[1] }
    end
  end
end
