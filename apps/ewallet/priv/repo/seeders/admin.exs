# This is the seeding script for User (admin & viewer users).
import EWalletDB.Helpers.Crypto, only: [generate_key: 1]
alias EWallet.Seeder
alias EWallet.Seeder.CLI
alias EWalletDB.{Account, Membership, Role, User}

admin_seeds = [
  # Seed an admin user for each account
  %{email: "admin_brand1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "admin_branch1@example.com", password: generate_key(16), metadata: %{}},

  # Seed a viewer user for each account
  %{email: "viewer_master@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_brand1@example.com", password: generate_key(16), metadata: %{}},
  %{email: "viewer_branch1@example.com", password: generate_key(16), metadata: %{}},
]

# Note that we use `account_name` instead of the account's `id` because
# the `id` is autogenerated, so we cannot know the `id` before hand.
memberships = [
  # Assign the admin user to its account
  %{email: "admin_brand1@example.com", role_name: "admin", account_name: "brand1"},
  %{email: "admin_branch1@example.com", role_name: "admin", account_name: "branch1"},

  # Assign the viewer user to its account
  %{email: "viewer_master@example.com", role_name: "viewer", account_name: "master_account"},
  %{email: "viewer_brand1@example.com", role_name: "viewer", account_name: "brand1"},
  %{email: "viewer_branch1@example.com", role_name: "viewer", account_name: "branch1"}
]

CLI.subheading("Seeding admin panel users:\n")

Enum.each(admin_seeds, fn(data) ->
  with nil <- User.get_by_email(data.email),
       {:ok, user} <- User.insert(data)
  do
    CLI.success("""
      Email    : #{user.email}
      Password : #{data.password || '<hashed>'}
      ID       : #{user.id}
    """)
  else
    %User{} = user ->
      CLI.warn("""
        Email    : #{user.email}
        Password : #{data.password || '<hashed>'}
        ID       : #{user.id}
      """)
    {:error, changeset} ->
      CLI.error("  Admin Panel user #{data.email} could not be inserted:")
      Seeder.print_errors(changeset)
  end
end)

CLI.subheading("Assigning roles to admin panel users:\n")

Enum.each(memberships, fn(membership) ->
  with %User{} = user       <- User.get_by_email(membership.email),
       %Account{} = account <- Account.get_by(name: membership.account_name),
       %Role{} = role       <- Role.get_by_name(membership.role_name),
       {:ok, _}             <- Membership.assign(user, account, role)
  do
    CLI.success("""
        Email : #{user.email}
        Role  : #{role.name} at #{account.name}
      """)
  else
    {:error, changeset} ->
      CLI.error("  Admin Panel user #{membership.email} could not be assigned:")
      Seeder.print_errors(changeset)
    _ ->
      CLI.error("  Admin Panel user #{membership.email} could not be assigned:")
      CLI.error("  Unable to parse the provided error.\n")
  end
end)
