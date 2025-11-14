class RegularExpression
  module Example
    module_function

    def categories
      orig = {}

      if I18n.exists?("regular_expressions.categories")
        begin
          locale_cats = I18n.t("regular_expressions.categories")
          if locale_cats.is_a?(Hash) && locale_cats.any?
            loaded = {}
            locale_cats.each do |slug, data|
              title = I18n.t("regular_expressions.categories.#{slug}.title", default: slug.to_s.split(/[-_]/).map(&:capitalize).join(" "))

              raw_examples = data["examples"] || data[:examples] || {}
              examples = if raw_examples.is_a?(Hash)
                           raw_examples.keys.sort_by { |k| k.to_i }.map do |k|
                             raw_examples[k] || raw_examples[k.to_s] || (k.respond_to?(:to_sym) ? raw_examples[k.to_sym] : nil)
                           end
              else
                           raw_examples
              end

              examples = Array(examples).map do |e|
                pattern = e && (e["pattern"] || e[:pattern])
                test = e && (e["test"] || e[:test])
                result = e && (e["result"] || e[:result])
                options = e && (e.key?("options") ? e["options"] : (e.key?(:options) ? e[:options] : ""))
                substitution = e && (e.key?("substitution") ? e["substitution"] : (e.key?(:substitution) ? e[:substitution] : ""))
                description = e && (e["description"] || e[:description])

                {
                  pattern: pattern,
                  test: test,
                  result: result,
                  options: options,
                  substitution: substitution,
                  description: description
                }
              end

              loaded[title] = {
                short: data["short"] || data[:short] || title,
                description: data["description"] || data[:description] || "",
                examples: examples
              }
            end

            orig = loaded if loaded.any?
          end
        rescue => e
          Rails.logger.debug("regexp helper load locales skipped: #{e.message}") if defined?(Rails)
        end
      end

      # Keep the loaded order from the YAML (do not apply a hard-coded priority order).

      translated = {}
      orig.each do |cat, data|
        cat_key = cat.to_s.parameterize

        short = I18n.t("regular_expressions.categories.#{cat_key}.short", default: data[:short])
        description = I18n.t("regular_expressions.categories.#{cat_key}.description", default: data[:description])

        examples = (data[:examples] || []).map.with_index do |ex, i|
          ex_dup = ex.dup

          %i[pattern test result options substitution description].each do |fld|
            locale_key = "regular_expressions.categories.#{cat_key}.examples.#{i}.#{fld}"

            if I18n.exists?(locale_key)
              ex_dup[fld] = I18n.t(locale_key)
            else
              ex_dup[fld] = ex[fld]
            end
          end

          ex_dup
        end

        translated[cat] = data.merge(short: short, description: description, examples: examples)
      end

      translated
    end

    def example_categories
      categories
    end

    # Return a lightweight list of categories (slug and short/description) without building examples.
    # This avoids constructing large example objects during initial page render.
    def category_list
      list = {}
      return list unless I18n.exists?("regular_expressions.categories")

      begin
        locale_cats = I18n.t("regular_expressions.categories")
        if locale_cats.is_a?(Hash)
          locale_cats.each do |slug, data|
            title = I18n.t("regular_expressions.categories.#{slug}.title", default: slug.to_s.split(/[-_]/).map(&:capitalize).join(" "))
            short = I18n.t("regular_expressions.categories.#{slug}.short", default: (data && (data[:short] || data["short"]) || title))
            desc = I18n.t("regular_expressions.categories.#{slug}.description", default: (data && (data[:description] || data["description"]) || ""))
            list[title] = { short: short, description: desc }
          end
        end
      rescue => e
        Rails.logger.debug("regexp helper category_list skipped: #{e.message}") if defined?(Rails)
      end

      # Return list in the order provided by the YAML file.

      list
    end

    # Load examples for a single category (by slug or parameterized key).
    # Returns a hash like { short: ..., description: ..., examples: [...] }
    def examples_for_category(key)
      return {} unless I18n.exists?("regular_expressions.categories")

      cat_key = key.to_s
      # Accept either parameterized slug or original title key
      begin
        locale_root = I18n.t("regular_expressions.categories")
        if locale_root.is_a?(Hash)
          # try to find matching key by parameterized name
          found = nil
          locale_root.each do |slug, data|
            candidate = slug.to_s
            if candidate == cat_key || candidate.parameterize == cat_key
              found = [slug, data]
              break
            end
          end

          return {} unless found

          slug, data = found

          title = I18n.t("regular_expressions.categories.#{slug}.title", default: slug.to_s.split(/[-_]/).map(&:capitalize).join(" "))

          raw_examples = data["examples"] || data[:examples] || {}
          examples = if raw_examples.is_a?(Hash)
                       raw_examples.keys.sort_by { |k| k.to_i }.map do |k|
                         raw_examples[k] || raw_examples[k.to_s] || (k.respond_to?(:to_sym) ? raw_examples[k.to_sym] : nil)
                       end
          else
                       raw_examples
          end

          examples = Array(examples).map do |e|
            pattern = e && (e["pattern"] || e[:pattern])
            test = e && (e["test"] || e[:test])
            result = e && (e["result"] || e[:result])
            options = e && (e.key?("options") ? e["options"] : (e.key?(:options) ? e[:options] : ""))
            substitution = e && (e.key?("substitution") ? e["substitution"] : (e.key?(:substitution) ? e[:substitution] : ""))
            description = e && (e["description"] || e[:description])

            {
              pattern: pattern,
              test: test,
              result: result,
              options: options,
              substitution: substitution,
              description: description
            }
          end

          short = I18n.t("regular_expressions.categories.#{slug}.short", default: (data["short"] || data[:short] || title))
          description = I18n.t("regular_expressions.categories.#{slug}.description", default: (data["description"] || data[:description] || ""))

          return { short: short, description: description, examples: examples }
        end
      rescue => e
        Rails.logger.debug("regexp helper examples_for_category skipped: #{e.message}") if defined?(Rails)
      end

      {}
    end

    # Return a random example (pick random category then random example within it).
    # Uses lightweight category selection to avoid building the whole examples map up-front.
    def random_example
      return {} unless I18n.exists?("regular_expressions.categories")

      begin
        locale_root = I18n.t("regular_expressions.categories")
        return {} unless locale_root.is_a?(Hash) && locale_root.any?

        # choose a random slug
        slug, data = locale_root.to_a.sample
        return {} unless data

        # Build examples for this slug and pick one
        raw_examples = data["examples"] || data[:examples] || {}
        examples = if raw_examples.is_a?(Hash)
                     raw_examples.keys.sort_by { |k| k.to_i }.map do |k|
                       raw_examples[k] || raw_examples[k.to_s] || (k.respond_to?(:to_sym) ? raw_examples[k.to_sym] : nil)
                     end
        else
                     raw_examples
        end

        arr = Array(examples).map do |e|
          {
            pattern: e && (e["pattern"] || e[:pattern]) || "",
            test: e && (e["test"] || e[:test]) || "",
            result: e && (e["result"] || e[:result]) || nil,
            options: e && (e.key?("options") ? e["options"] : (e.key?(:options) ? e[:options] : "")),
            substitution: e && (e.key?("substitution") ? e["substitution"] : (e.key?(:substitution) ? e[:substitution] : "")),
            description: e && (e["description"] || e[:description]) || ""
          }
        end

        chosen = arr.compact.sample || {}

        title = I18n.t("regular_expressions.categories.#{slug}.title", default: slug.to_s.split(/[-_]/).map(&:capitalize).join(" "))
        short = I18n.t("regular_expressions.categories.#{slug}.short", default: (data["short"] || data[:short] || title))
        description = I18n.t("regular_expressions.categories.#{slug}.description", default: (data["description"] || data[:description] || ""))

        { category: title, short: short, description: description }.merge(chosen)
      rescue => e
        Rails.logger.debug("regexp helper random_example skipped: #{e.message}") if defined?(Rails)
        {}
      end
    end
  end
end
