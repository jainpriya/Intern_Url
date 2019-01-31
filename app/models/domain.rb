class Domain < ApplicationRecord
	validates :domain_name, presence: true
	validates :short_domain, presence: true
end
