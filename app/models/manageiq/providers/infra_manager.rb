module ManageIQ::Providers
  class InfraManager < BaseManager
    require_nested :Template
    require_nested :ProvisionWorkflow
    require_nested :Vm
    require_nested :VmOrTemplate

    include AvailabilityMixin

    has_many :host_hardwares,             :through => :hosts, :source => :hardware
    has_many :host_operating_systems,     :through => :hosts, :source => :operating_system
    has_many :host_storages,              :through => :hosts
    has_many :host_switches,              :through => :hosts
    has_many :host_networks,              :through => :hosts, :source => :networks
    has_many :snapshots,                  :through => :vms_and_templates
    has_many :switches, -> { distinct },  :through => :hosts
    has_many :lans, -> { distinct },      :through => :hosts
    has_many :subnets, -> { distinct },   :through => :lans
    has_many :networks,                   :through => :hardwares
    has_many :guest_devices,              :through => :hardwares

    class << model_name
      define_method(:route_key) { "ems_infras" }
      define_method(:singular_route_key) { "ems_infra" }
    end

    #
    # ems_timeouts is a general purpose proc for obtaining
    # read and open timeouts for any ems type and optional service.
    #
    # :ems
    #   :ems_redhat    (This is the type parameter for these methods)
    #     :open_timeout: 3.minutes
    #     :inventory   (This is the optional service parameter for ems_timeouts)
    #        :read_timeout: 5.minutes
    #     :service
    #        :read_timeout: 1.hour
    #
    def self.ems_timeouts(type, service = nil)
      ems_settings = ::Settings.ems[type]
      return [nil, nil] unless ems_settings

      service = service.try(:downcase)
      read_timeout = ems_settings.fetch_path([service, :read_timeout].compact).try(:to_i_with_method)
      open_timeout = ems_settings.fetch_path([service, :open_timeout].compact).try(:to_i_with_method)
      [read_timeout, open_timeout]
    end

    def validate_authentication_status
      {:available => true, :message => nil}
    end

    def clusterless_hosts
      hosts.where(:ems_cluster => nil)
    end
  end

  def self.display_name(number = 1)
    n_('Infrastructure Manager', 'Infrastructure Managers', number)
  end
end
