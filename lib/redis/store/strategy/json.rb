require 'oj'

class Redis
  class Store < self
    module Strategy
      module Json
        private
        def _dump(object)
          Oj.dump(object)
        end

        def _load(string)
          Oj.load(string)
        end
      end
    end
  end
end
