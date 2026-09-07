# Trellixe — Product Brief

*The constitution for this repo. Every slice of work — reskin, bugfix, or
rethink — is judged against this file. Update it when the product changes,
not when opinions do.*

## 1. One line

A shared relationship tracker for church outreach teams that carries every
visitor from street invitation to active membership without anyone falling
through the cracks.

## 2. The problem

Outreach produces names — on the street Saturday, at the door Sunday — and
teams lose them. Numbers live in individual phones, prayer requests live in
heads, and by Monday nobody remembers who to call. Trellixe replaces
scattered memory with **one shared list per team** where every person, every
touch, and every next action is visible to everyone who needs it.

## 3. Who it's for

- **Cell members (teams of ~5)** on the field with phones: capture people in
  seconds, see the same list, never double-enter.
- **Welcome / assimilation teams** at services: check guests in at a crowded
  door, route people between cells, assign transport and visits.
- **Branch overseers**: see outreach turn into attendance turn into
  belonging, cell by cell — conversion, not raw counts.

## 4. The core loop (the whole product in four steps)

1. **Invite** — capture name, number, and one line of *context* (prayer
   point, situation, who brought them) at the moment of meeting.
2. **Remind** — nudge the team before the event so invitees actually show up.
3. **Welcome** — one-tap attendance at the door; this single action triggers
   everything downstream.
4. **Keep** — attendance automatically queues a follow-up task with full
   context; every call/text/visit is logged to a shared per-person timeline
   so the next volunteer never starts cold.

**If a feature doesn't serve this loop, it doesn't belong in v1.**

## 5. Domain model

- **Workspace** (cell → branch → zone hierarchy can come later; v1 needs one
  shared workspace with member/admin roles and seat limits).
- **Contact**: name, phone/email, rich narrative context, tags. Owned by the
  workspace, never by the individual who entered them.
- **Event + Event Series**: one-off outreaches/services plus recurring
  meetings with occurrences generated from rules.
- **Invitation** (guest × event, `invited / attended / declined`): the
  pipeline record. Attendance spawns follow-up work — including
  automatically, when tags link contacts to series occurrences.
- **Follow-up Task**: owned by one volunteer, due-dated,
  completable/snoozable. The unit of "who calls whom by when."
- **Interaction Log**: every completed touch, appended to the contact's
  timeline.
- **Tag**: the connective tissue — grouping contacts *and* driving automatic
  invitations.

## 6. V1 scope

**In:** contact capture with context, Sunday check-in (bulk + single),
auto-queued follow-ups, interaction timeline, tags + tag-driven
auto-invites, series scheduling, team invites with roles, attendance and
invite→follow-up conversion stats.

**Explicitly NOT v1 — do not build these, however helpful they seem:**

- QR self-check-in for crusades
- Free-form manual to-dos
- Per-workspace reminder cadences
- Zonal / regional oversight portals

## 7. UX principles

- **Phone first, door-tested: the field interface is the real product;
  desktop is the admin view.** The defining moment is a volunteer at a
  crowded door or a dusty roadside — design for *that* person first:
  - *Big tap targets.* ~48px rows tappable without looking; no 16px
    checkboxes, no cursor-only ellipsis menus. Primary actions live at the
    bottom of the phone screen, where thumbs rest.
  - *Survives glare.* Status differs in shape and weight (filled vs.
    outline, bold label), never just shade-vs-shade.
  - *Forgiving of bad networks.* Taps acknowledge instantly (optimistic UI)
    and sync when connectivity returns — never a spinner that eats a
    check-in.
  - *Cheap devices.* Small screens, slow CPUs, no 500KB pages or
    desktop-only layouts.
  - The test is literal: *could a greeter use this while welcoming
    someone?* If an interaction needs small text, precise tapping, or a
    live connection, it fails — however clean it looks on a laptop.
- **Two modes, not one screen.** One screen per job that serves both crowd
  and desk serves neither. Split them:
  - *Field mode (crowd, hurry):* full-screen, one job, no chrome.
    Search-as-you-type guest rows, tap-to-toggle attendance, a live
    "12/40 checked in" counter. Nothing deletable, nothing configurable —
    speed only.
  - *Manage mode (desk, detail):* editing, removing, filtering, history,
    bulk operations. Allowed to be dense.
  - Same data, never the same screen.
- **Sequential, not tabular.** Monday work is a queue — one person, their
  context, log it, next — not a spreadsheet with a bulk bar.
- **No orphans.** Every name has a next action or a reason it doesn't;
  "forgotten" must be a state that can't exist.
- **Church-shaped language.** Guests, welcome teams, cells, services —
  never leads, pipelines, or deals.

## 8. Design system (decided, not to be re-debated per slice)

- **Tailwind CSS v4** (`tailwindcss-rails`, CSS-first config in
  `app/assets/tailwind/application.css`). css-zero is gone; do not
  reintroduce it or any second framework.
- **Algae palette**: deep `#13714C` · mid `#3AB67D` · light `#A2E494` ·
  mist `#E9EBED`. Dark surfaces: page `#0C1210`, card `#131B17`,
  ink `#E7ECE9`, subtle `#9AA6A0`. No gradients, no blue/purple SaaS
  tropes, no emoji in UI.
- **Dark mode contract**: the `color-scheme` Stimulus controller sets
  `data-color-scheme="light|dark"` on `<body>` (resolving `system` itself);
  the Tailwind `dark` variant keys off that attribute. Every new view ships
  both modes — follow the per-area token map, don't invent new dark colors.
- **Type**: Google Sans (display) + Open Sans (body), self-hosted via
  `shared/_font_faces` (font URLs must stay Propshaft-digested — never put
  relative `url()` font paths in the Tailwind build input).
- **Third-party widget CSS** (TomSelect, flatpickr) is imported pinned from
  CDN at the top of the Tailwind input with Algae theme overrides. Any new
  JS widget that ships CSS gets the same treatment — unstyled widgets are a
  recurring bug class here.
- **Native platform first**: `<dialog>`, `popover="auto"` (never
  `popover="true"`), Turbo Frames/Streams. Custom JS only where the
  platform ends.

## 9. UI construction without ViewComponents (decided)

No ViewComponent dependency. Consistency comes from three tiers, all
already in use — compose from them before inventing anything new:

1. **Helpers for atoms** — `icon(name, css:)`, `modal_dialog`,
   `full_title`, `user_avatar_url`, `account_initials`,
   `vapid_public_key`. Small, logic-heavy, unit-testable.
2. **Strict-contract partials for molecules** — fixed locals, documented
   in a comment at the top of each file. Current inventory:
   - `shared/_empty_state` (`title, body, action?, icon_name?`)
   - `shared/_flash` (notice/alert, auto-dismisses)
   - `shared/_dialog` / `shared/_modal` (`trigger, title, label?, size?,
     content`)
   - `shared/_pagination` (`pagy`)
   - `shared/_auth_shell` (`title, subtitle?` + block)
   - `shared/_font_faces` (no locals)
   - `shared/_settings_back_button` (no locals)
   - `tags/_manager` (`tags, tag, list_id`)
   - `dashboards/_follow_up_row`, `dashboards/_upcoming_event_row`
     (`task` / `event`)
   - `follow_up_tasks/_queue` (`queue, pagy, context`) with
     `follow_up_tasks/_queue_current` (`task, context`) and
     `follow_up_tasks/_queue_up_next_row` (`task, context`)
3. **Layout-partials for shells** — `render layout:` (auth shell pattern)
   for page/modal shells.

**Inventory rule:** new views compose from §9 first. A new shared piece
must be added to this section in the same commit that introduces it.
Variant drift (`_contact_row_v2`) is a review-blocking offense — extend
the original behind a local instead.

## 10. Transitional code (allowed to exist, scheduled to die)

- **`application.css` compat bridge** (`.btn/.input/.card/.table/...`):
  exists only so the migration landed safely. Rethink slices delete the
  classes they replace; the bridge disappears slice by slice, never in one
  big-bang.
- **Dual desktop-table + mobile-card list partials**: same treatment —
  each unified list deletes its pair.

## 11. Branch map & standing rules

- `master` — last stable. `redesign/tailwind-ui` — Tailwind system of
  record. `rethink/field-ux` — structural UX work, branched off
  `redesign`, merged back slice by slice. One eventual merge to master.
- **Slices replace, never coexist.** A landed slice deletes what it
  replaces in the same merge.
- **Backend contracts are load-bearing**: Turbo Frame ids, `dom_id`s,
  Ransack/Pagy params, routes, model callbacks (attendance → task →
  reminder). Change a view freely; change a contract only with a test.
- **Verify like this broke us once**: template compile check over all
  views, `tailwindcss:build`, RuboCop on touched Ruby, `node --check` on
  touched Stimulus (knowing it can't catch runtime errors — new controller
  logic gets a runtime harness or a click test), Brakeman quiet, HTTP
  spot-checks. Suite runs before any branch merge.
- **Deferred features (§6) stay deferred** until this brief says otherwise.
