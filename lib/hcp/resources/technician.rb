module Hcp
  # A person the business sends out, whom Housecall Pro calls an employee.
  class Technician < Company::Technician
    # The node keys Housecall Pro spells otherwise than the vocabulary.
    def self.keys = { name: :first_name, surname: :last_name }
  end
end
