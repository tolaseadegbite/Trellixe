module PublicIdentifiable
  extend ActiveSupport::Concern

  # Custom alphabet: 58 chars (No 0, O, I, l)
  # 58^12 = 1.7 Quindecillion combinations. Collision is statistically impossible.
  ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".chars.freeze

  included do
    class_attribute :public_id_prefix
    before_create :generate_public_id
  end

  class_methods do
    def has_public_id(prefix:)
      self.public_id_prefix = prefix
    end

    def find_by_public_id(id)
      find_by(public_id: id)
    end

    def find_by_public_id!(id)
      find_by!(public_id: id)
    end
  end

  # Override to_param so paths become /projects/proj_abc123
  def to_param
    public_id
  end

  private

  def generate_public_id
    return if public_id.present?

    loop do
      # Highly performant native Ruby sampling
      random_str = (0...12).map { ALPHABET.sample }.join
      self.public_id = "#{public_id_prefix}_#{random_str}"
      break unless self.class.exists?(public_id: public_id)
    end
  end
end
