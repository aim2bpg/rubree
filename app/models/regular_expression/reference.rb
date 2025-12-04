class RegularExpression
  module Reference
    module_function

    def sections
      orig = [
        { key: "character-classes-anchors", col_class: "grid-cols-[65px_1fr]" },
        { key: "common-patterns", col_class: "grid-cols-[20px_1fr]" },
        { key: "groups-quantifiers", col_class: "grid-cols-[50px_1fr]" },
        { key: "group-groups-assertions", col_class: "grid-cols-[90px_1fr]" }
      ]

      orig.map.with_index do |sec, s_idx|
        key = sec[:key]
        translated_title = I18n.t("reference.sections.#{key}.title", default: nil)
        translated_title ||= I18n.t("regular_expressions.reference.sections.#{key}.title", default: key.to_s.tr("-", " ").capitalize)

        prefixes = ["reference.", "regular_expressions.reference.", "application.reference.", "application.regular_expressions.reference."]

        patterns_hash = nil
        descs_hash = nil

        prefixes.each do |pref|
          break if patterns_hash && descs_hash

          if patterns_hash.nil?
            cand = I18n.t("#{pref}sections.#{key}.patterns", default: nil)
            cand ||= I18n.t("#{pref}sections.#{key}.items.patterns", default: nil)
            patterns_hash = cand unless cand.nil? || (cand.respond_to?(:empty?) && cand.empty?)
          end

          if descs_hash.nil?
            cand2 = I18n.t("#{pref}sections.#{key}.items", default: nil)
            descs_hash = cand2 unless cand2.nil? || (cand2.respond_to?(:empty?) && cand2.empty?)
          end
        end

        patterns_hash ||= {}
        descs_hash ||= {}
        descs_hash = descs_hash.dup
        if descs_hash.is_a?(Hash)
          descs_hash.delete(:patterns)
          descs_hash.delete("patterns")
        end

        raw_keys = []
        raw_keys.concat(patterns_hash.keys) if patterns_hash.is_a?(Hash)
        raw_keys.concat(descs_hash.keys) if descs_hash.is_a?(Hash)
        indices = raw_keys.map(&:to_s).uniq.sort_by { |k| k.to_i }

        translated_items = indices.map do |i|
          idx = i.to_i
          pat = nil
          if patterns_hash.is_a?(Hash)
            pat = patterns_hash[idx] || patterns_hash[i.to_sym] || patterns_hash[i]
          end

          desc = nil
          if descs_hash.is_a?(Hash)
            desc = descs_hash[idx] || descs_hash[i.to_sym] || descs_hash[i]
          end

          next if pat.nil? && desc.nil?
          [pat || "", desc || ""]
        end.compact

        { title: translated_title, col_class: sec[:col_class], items: translated_items }
      end
    end

    # Return modifier options (flags) defined in the reference locale.
    def options
      prefixes = ["reference.", "regular_expressions.reference.", "application.reference.", "application.regular_expressions.reference."]
      translations = nil

      prefixes.each do |pref|
        cand = I18n.t("#{pref}.options", default: nil)
        translations = cand unless cand.nil? || (cand.respond_to?(:empty?) && cand.empty?)
        break if translations
      end

      # final fallback to older path specifically under regular_expressions
      translations ||= I18n.t("regular_expressions.reference.options", default: {})
      return [] unless translations.is_a?(Hash)

      translations.select { |k, _| k.to_s.length == 1 }.map { |flag, desc| [flag.to_s, desc.to_s] }
    end
  end
end
