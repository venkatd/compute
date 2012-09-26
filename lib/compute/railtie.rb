module Compute
  class Railtie < Rails::Railtie
    initializer 'compute.model_additions' do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.send :include, Compute
      end
    end
  end
end
