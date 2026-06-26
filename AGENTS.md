# Trellixe — Agentic Coding Guide

## Build / Lint / Test
```bash
bin/setup && bin/rails db:create db:migrate db:seed
bin/rails test                                               # all (except system)
bin/rails test:system                                        # system tests only
bin/rails db:test:prepare test test:system                   # CI full suite
bin/rails test test/models/contact_test.rb                   # single file
bin/rails test test/controllers/contacts_controller_test.rb:8 # single method
bin/rails test -n "/should create/"                          # pattern match
bin/rubocop      && bin/rubocop -a       && bin/rubocop -A   # check / safe / all
bin/brakeman --no-pager && bin/importmap audit && bin/dev
```
## Project Architecture
**Rails 8.0.2** · **Ruby 3.4.5** · PostgreSQL (primary) + SQLite3 (queue/cache/cable)
- **Hotwire** (Turbo + Stimulus) with importmap (no bundler, no npm)
- **css-zero** framework: utility classes (`btn`, `input`, `flex`, `gap-half`, `mbe-4`)
- Custom utilities in `app/assets/stylesheets/utilities/utilities.css`: `wrap-anywhere`, `min-i-0`, `i-full`, `overflow-ellipsis`, `overflow-y-auto`, responsive `show\@md`/`hide\@md`, etc.
- **Pagy** for pagination, **Ransack** for search/filtering
- **Noticed** for in-app notifications, **Solid Queue** for background jobs
- **Authentication Zero**: bcrypt, sessions, OmniAuth, sudo/masquerade
- Multi-tenant via `Current` (ActiveSupport::CurrentAttributes)
- Public IDs via `PublicIdentifiable` concern (`user_abc123`)
## Code Style
### Imports & Requires
App code needs zero requires — Rails autoloads. Test files start with:
```ruby
require "test_helper"
require "application_system_test_case"  # system tests only
```
### Formatting
- 2-space soft indent, no tabs. Follow `rubocop-rails-omakase` defaults (`.rubocop.yml`)
- `private`/`protected` indented one level inside class body
- `%w[]` for word arrays, `%i[]` for symbol arrays. Hash syntax: `{ key: value }` (Ruby 3+)
- No `;`, no trailing commas
### Naming
| Thing | Convention | Example |
|-------|-----------|---------|
| Files | snake_case | `contacts_controller.rb` |
| Classes | CamelCase | `ContactsController` |
| Methods | snake_case | `set_current_account` |
| Predicates | trailing `?` | `user_signed_in?`, `today?` |
| Scopes | short descriptive | `past`, `upcoming` |
| Private callbacks | `set_` prefix | `set_contact`, `set_event` |
| Concerns | descriptive | `PublicIdentifiable`, `AccountScoped` |

### Models (`ApplicationRecord`)
Order: **validations → associations → scopes → callbacks → custom → private**
```ruby
class Contact < ApplicationRecord
  validates :first_name, presence: true
  belongs_to :owner, polymorphic: true
  has_many :invitations, dependent: :destroy
  ransack_alias :combined_search, :first_name_or_last_name_or_email
  def self.ransackable_attributes(auth_object = nil) = %w[ id first_name last_name email combined_search ]
  def full_name = "#{first_name} #{last_name}"
end
```
- Scope queries to `Current.account`. Use `has_public_id prefix: "contact"` for public IDs
- Use `enum :status, { invited: 0, attended: 1, declined: 2 }` for status fields
- Available concerns: `PublicIdentifiable`, `AccountScoped`
### Controllers
Two base classes: `ApplicationController` (public/auth) and `DashboardsController < ApplicationController` (authenticated, layout "dashboard").
```ruby
class ContactsController < DashboardsController
  before_action :set_contact, only: %i[ show edit update destroy ]

  def index
    records = Current.account.contacts.order(created_at: :desc)
    @search = records.ransack(params[:q])
    @pagy, @contacts = pagy(@search.result)
  end

  def create
    @contact = Current.account.contacts.new(contact_params)
    respond_to do |format|
      if @contact.save
        flash.now[:notice] = "Contact created."; format.turbo_stream
      else
        flash.now[:alert] = @contact.errors.full_messages.to_sentence
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
  end

  private
    def set_contact = @contact = Current.account.contacts.find(params[:id])
    def contact_params = params.expect(:contact, [:first_name, :last_name, :email, :phone_number])
end
```
Key rules:
- **Scope everything** to `Current.account` — never `current_user.contacts`
- `flash.now` for Turbo Stream, `redirect_to ... notice:` for HTML
- Prefer `params.expect(...)` (Rails 8) over `params.require(...).permit(...)`
- Always provide Turbo Stream + HTML via `respond_to do |format|`

### Views & CSS
- `.html.erb` for pages, `.turbo_stream.erb` for Turbo Stream responses
- Use `dom_id(record)` for HTML IDs
- **css-zero utility classes**: `btn`, `btn--icon`, `btn--subtle`, `btn--negative`, `btn--primary`, `input`, `flex`, `flex-col`, `items-center`, `items-start`, `justify-between`, `gap` (0.5rem), `gap-half` (0.25rem)
- **Custom utilities** (`app/assets/stylesheets/utilities/utilities.css`): `wrap-anywhere`, `wrap-break-word`, `overflow-ellipsis`, `overflow-clip`, `min-i-0`, `i-full`, `max-i-full`, `b-full`, `overflow-hidden`, `overflow-y-auto`, `overflow-x-auto`, `sticky`, `show\@md`, `hide\@md`, all margin/padding via logical properties (`mbe-*`, `mis-*`, `pis-*`, etc.)
- **Hover card background**: `hover:bg-shade transition` — standard pattern

### Flex text overflow fix (known gotcha)
When text inside a flex item refuses to wrap (e.g., inside a popover), use CSS Grid with `minmax(0, 1fr)` on the container and inline `style="overflow-wrap: break-word; word-break: break-word; white-space: normal;"` on the `<p>` tag together. Set `min-inline-size: 0` on the text container. For scroll containers, add `overflow-x: hidden` alongside `overflow-y: auto` to prevent scrollbar-width-induced horizontal scrollbar.

### Avatar helper
```ruby
def user_avatar_url(user, size: 80)
  if user.avatar.attached? && user.avatar.attachment&.persisted?
    url_for(user.avatar)
  else
    user.gravatar_url(size: size)
  end
end
```
Views: `image_tag user_avatar_url(user, size: 32), size: 32, class: "rounded-full"`.

### JavaScript (Stimulus + Importmap)
- Controllers in `app/javascript/controllers/` — 40+. Registration is automatic via `pin_all_from` in importmap.
- Notable: `dialog`, `modal`, `popover`, `combobox`, `flash`, `sidebar`, `tabs`, `menu`, `color-scheme`, `datepicker`, `search_filter`, `autosave`, `carousel`, `chart`, `check_all`, `collapsible`, `command`, `context_menu`, `debounce`, `disclosure`, `dropzone`, `dual_range`, `form`, `fullscreen`, `hello`, `hotkey`, `input_clearable`, `input_copyable`, `inputmask`, `input_revealable`, `lightbox`, `local_time`, `push_subscription`, `timezone`, `web_share`
- Stimulus: `data-controller="name"`, `data-action="event->controller#method"`, `data-controller-target="name"`

### Notification streams
```erb
<%= turbo_stream_from "notifications_#{current_user.id}_global" %>
<%= turbo_stream_from "notifications_#{current_user.id}_account_#{Current.account.id}" %>
```

### Testing (Minitest)
- Fixtures in `test/fixtures/*.yml`, loaded via `fixtures :all` in `test_helper.rb`
- Helper `sign_in_as(user)` available in all integration tests (posts to sign_in with `Secret1*3*5*`)
- System tests: `ApplicationSystemTestCase` (Selenium headless Chrome, 1400×1400)
- Standard pattern: `require "test_helper"`, extend `ActionDispatch::IntegrationTest`, use `setup` block for fixtures

### Error Handling
- Scoped `find` to prevent cross-tenant data leaks: `Current.account.contacts.find(params[:id])`
- Non-bang `update`/`create`: check return value, branch on success/failure
- Bang `destroy!`: raises on failure
- User-facing errors: `@contact.errors.full_messages.to_sentence`
### Permissions
Roles (`member`/`admin`) live on `Membership` as a string enum. Always use semantic helpers from the `Permissionable` concern (included in `ApplicationController`):

| Helper | Member | Admin |
|--------|--------|-------|
| `can_view_team?` | ✅ | ✅ |
| `can_invite_members?` | ❌ | ✅ |
| `can_manage_members?` | ❌ | ✅ |
| `can_manage_settings?` | ❌ | ✅ |
| `can_manage_billing?` | ❌ | ✅ |
| `can_manage_all_logs?` | ❌ | ✅ |
| `can_edit_log?(log)` | owner only | ✅ |
| `can_delete_workspace?` | ❌ | ✅ |

```erb
<%# Views — use semantic helpers, never inline current_role == "admin" %>
<% if can_manage_members? %>
  <%= link_to "Invite", new_team_invitation_path %>
<% end %>
```

```ruby
# Controllers — use ensure_admin! before_action for admin-only actions
class TeamInvitationsController < DashboardsController
  before_action :ensure_admin!, only: %i[ new create destroy resend ]
end

# For ownership-based gating, use can_edit_log?
def authorize_owner!
  unless can_edit_log?(@interaction_log)
    redirect_back_or_to contact_path(@interaction_log.contact), alert: "Permission denied."
  end
end
```
- `ensure_admin!` is defined in `ApplicationController` (redirects to `root_path`)
- Ownership checks (e.g., `@log.user == current_user`) are still valid for personal resources
- Add new semantic methods to `app/models/concerns/permissionable.rb` as roles evolve

### Multi-tenancy Pattern
```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user_agent, :ip_address, :account
  delegate :user, to: :session, allow_nil: true
end
```
Callback order in `ApplicationController`: `set_current_request_details` → `set_current_user_from_session` → `set_current_account` → `authenticate`. All queries: `Current.account.contacts`, `Current.account.events`, etc.
