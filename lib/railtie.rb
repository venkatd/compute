module Compute
  class Railtie < Rails::Railtie
    initializer 'compute.model_additions' do
      ActiveSupport.on_load :active_record do
      end
    end
  end
end
