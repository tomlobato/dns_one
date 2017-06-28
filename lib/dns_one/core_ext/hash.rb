class Hash
    def symbolize_keys
        each_with_object({}) { |(k, v), h| h[k.to_sym] = v.is_a?(Hash) ? v.symbolize_keys : v }
    end
end
