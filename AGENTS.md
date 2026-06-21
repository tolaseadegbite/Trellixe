# Trellixe — Agentic Coding Guide

## Build / Lint / Test

```bash
# Setup
bin/setup
bin/rails db:create db:migrate db:seed

# Run all tests (except system)
bin/rails test

# Run system tests only
bin/rails test:system

# CI: full suite (used in .github/workflows/ci.yml)
bin/rails db:test:prepare test test:system

# Single test file
bin/rails test test/models/contact_test.rb
bin/rails test test/controllers/contacts_controller_test.rb

# Single test method (line number)
bin/rails test test/controllers/contacts_controller_test.rb:8

# Run tests matching a pattern
bin/rails test -n "/should create/"

# Lint (rubocop-rails-omakase style)
bin/rubocop            # Check
bin/rubocop -a         # Auto-correct safe offenses
bin/rubocop -A         # Auto-correct all

# Security
bin/brakeman --no-pager
bin/importmap audit

# Dev server (web + jobs + solid_queue)
bin/dev
```

## Project Architecture

**Rails 8.0.2** · **Ruby 3.4.5** · PostgreSQL (primary) + SQLite3 (queue/cache/cable)
- Hotwire (Turbo + Stimulus) with importmap (no bundler)
- **css-zero** framework: utility classes (`btn`, `input`, `flex`, `gap-half`, `mbe-4`)
- **Pagy** for pagination, **Ransack** for search/filtering
- **Noticed** for in-app notifications, **Solid Queue** for background jobs
- **Authentication Zero**: bcrypt, sessions, OmniAuth, sudo/masquerade
- Multi-tenant via `Current` (ActiveSupport::CurrentAttributes)
- Public IDs via `PublicIdentifiable` concern (`user_abc123`)

## Code Style

### Imports & Requires
App code needs zero requires — Rails autoloading handles it. Test files start with:
```ruby
require "test_helper"
require "application_system_test_case"  # system tests only
```

### Formatting
- 2-space soft indent, no tabs
- Follow `rubocop-rails-omakase` defaults (inherited in `.rubocop.yml`)
- `private` / `protected` indented one level inside class body
- Use `%w[]` for word arrays, `%i[]` for symbol arrays
- Hash syntax: `{ key: value }` (Ruby 3+)
- No `;` for statement separation, no trailing commas

### Naming
| Thing | Convention | Example |
|-------|-----------|---------|
| Files | snake_case | `contacts_controller.rb` |
| Classes/Modules | CamelCase | `ContactsController` |
| Methods | snake_case | `set_current_account` |
| Boolean predicates | trailing `?` | `user_signed_in?`, `admin?`, `today?` |
| Scopes | short descriptive | `past`, `upcoming`, `in_range` |
| Private callbacks | `set_` prefix | `set_contact`, `set_event` |
| Concerns | descriptive | `PublicIdentifiable`, `AccountScoped` |

### Models (`ApplicationRecord`)
Order within class: **validations → associations → scopes → callbacks → custom methods → private**
```ruby
class Contact < ApplicationRecord
  # Validations
  validates :first_name, presence: true

  # Associations
  belongs_to :owner, polymorphic: true
  has_many :invitations, dependent: :destroy

  # Ransack search config
  ransack_alias :combined_search, :first_name_or_last_name_or_email
  def self.ransackable_attributes(auth_object = nil)
    %w[ id first_name last_name email combined_search ]
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
```
- Always scope queries to `Current.account` for multi-tenant models
- Use `enum :status, { invited: 0, attended: 1, declined: 2 }` for status fields
- Use `has_public_id prefix: "contact"` (via `PublicIdentifiable` concern)

### Controllers
Two base classes:
- `ApplicationController` — public/auth pages (sessions, registrations)
- `DashboardsController < ApplicationController` — authenticated pages (layout "dashboard")

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
    @contact.creator = current_user
    respond_to do |format|
      if @contact.save
        flash.now[:notice] = "Contact created."
        format.turbo_stream
      else
        flash.now[:alert] = @contact.errors.full_messages.to_sentence
        format.turbo_stream { render status: :unprocessable_entity }
      end
    end
  end

  private

  def set_contact
    @contact = Current.account.contacts.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(:first_name, :last_name, :email, :phone_number)
  end
end
```

Key rules:
- **Scope everything** to `Current.account` — never `current_user.contacts`
- Use `flash.now[:notice/alert]` for Turbo Stream responses, `redirect_to ... notice:` for HTML
- Always provide Turbo Stream + HTML fallback via `respond_to do |format|`
- Use `params.expect(...)` (Rails 8) or `params.require(...).permit(...)` for strong params
- `render status: :unprocessable_entity` on validation failures

### Views (ERB)
- `.html.erb` for full page renders, `.turbo_stream.erb` for Turbo Stream responses
- CSS classes from **css-zero**: `btn`, `btn--icon`, `btn--subtle`, `btn--negative`, `input`, `flex`, `flex-col`, `items-center`, `gap`, `gap-half`, `mbe-4`, `mis-3`, `mbs-2`, `i-full`, `text-sm`, `text-subtle`, `text-red-500`
- Use `dom_id(record)` for HTML IDs
- Stimulus: `data-controller="name"`, `data-action="event->controller#method"`, `data-controller-target="name"`

### JavaScript (Stimulus + Importmap)
- Controllers in `app/javascript/controllers/` — one file per controller
- No npm / webpack — managed via `config/importmap.rb`
- Controller registration is automatic (via `pin_all_from` in importmap)
- Existing controllers: `dialog`, `modal`, `popover`, `combobox`, `flash`, `sidebar`, `tabs`, `menu`, `color-scheme`, `datepicker`, `search_filter`, etc.

### Testing (Minitest)
```ruby
# test/controllers/contacts_controller_test.rb
require "test_helper"

class ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @contact = contacts(:one)
  end

  test "should get index" do
    get contacts_url
    assert_response :success
  end

  test "should create contact" do
    assert_difference("Contact.count") do
      post contacts_url, params: { contact: { email: @contact.email, first_name: @contact.first_name } }
    end
    assert_redirected_to contact_url(Contact.last)
  end
end
```
- Fixtures in `test/fixtures/*.yml`, loaded via `fixtures :all` in `test_helper.rb`
- Helper `sign_in_as(user)` available in all tests (posts to `sign_in_url` with `Secret1*3*5*`)
- System tests use `ApplicationSystemTestCase` (Selenium headless Chrome, 1400×1400)

### Error Handling
- Scoped `find` to prevent cross-tenant data leaks: `Current.account.contacts.find(params[:id])`
- Non-bang `update`/`create` — check return value, branch on success/failure
- Bang `destroy!` — raises on failure
- User-facing errors: `@contact.errors.full_messages.to_sentence`

### Multi-tenancy Pattern
```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user_agent, :ip_address, :account
  delegate :user, to: :session, allow_nil: true
end

# In ApplicationController — callback order matters:
# 1. set_current_request_details (IP, User-Agent)
# 2. set_current_user_from_session
# 3. set_current_account (requires user)
# 4. authenticate
```
All account-scoped queries: `Current.account.contacts`, `Current.account.events`, etc.
