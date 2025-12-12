User.find_or_create_by!(email: "demo@example.com") do |u|
  u.name = "Demo User"
end
