module AccountsHelper
  # Generates initials from the account name (e.g. "Red Bull" -> "RB")
  def account_initials(account)
    return "?" unless account&.name

    # Split by space, take first 2 words, take first letter of each, join and upcase
    account.name.split.first(2).map(&:first).join.upcase
  end
end
