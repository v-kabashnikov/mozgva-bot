require 'rails_helper'

RSpec.describe User, type: :model do
  it { should validate_uniqueness_of(:telegram_id) }
end