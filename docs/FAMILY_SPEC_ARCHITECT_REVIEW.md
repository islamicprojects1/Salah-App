# Senior Product Architect Review — Family Groups Spec

**Document reviewed:** `FAMILY_GROUPS_SPEC_AND_PHILOSOPHY.md`  
**Reviewer:** Senior Product Architect (no-flattery mode)

---

## 1. Critical Gaps (What’s Completely Missing)

### Gap 1: Admin succession when admin is gone

**Missing:** No handling when the admin deletes the app, dies, or loses access.

**Why it’s a real problem:**  
- The spec says “admin selects a new admin when leaving” but nothing for involuntary exit.  
- Groups become orphaned, invite links keep working, no one can manage.  
- Result: ghost groups, no way to remove bad members or update settings.

**Fix:** Define admin succession: e.g. auto-promote oldest active member after X months of admin inactivity, or require “deputy admin” at creation. Add explicit “orphan group” handling (e.g. show warning, allow members to request dissolution).

---

### Gap 2: Auth required before joining a group

**Missing:** No flow for joining via link before the user has an account.

**Why it’s a real problem:**  
- Deep link opens app → user taps “join” → nothing to attach membership to.  
- Ambiguous error; user may think the link is wrong and re-share it.

**Fix:** Require sign-in/register before join. Store `pending_invite` (groupId, inviteCode) and complete join after auth. UX: “Sign in or register to join this group.”

---

### Gap 3: Invite link/code lifetime and abuse

**Missing:** No expiry, no limit on uses, no revocation.

**Why it’s a real problem:**  
- Link shared broadly → strangers join.  
- No way to stop it except deleting the group.  
- No control over who joins once the link is leaked.

**Fix:**  
- Invite config: expiry (24h / 7d / never) and/or max uses (e.g. 50).  
- Option to regenerate invite code and invalidate old links.  
- Document that v1 can start with “never expires” and add limits later.

---

### Gap 4: Shadow member → real member migration

**Missing:** No path for a shadow member who later gets a phone and installs the app.

**Why it’s a real problem:**  
- Child added as shadow at 8; at 12 they install the app.  
- No way to merge shadow identity with new account.  
- Either duplicates in the group or broken X/Y logic.

**Fix:**  
- Optional `shadowContactHint` (email/phone) stored when adding shadow (admin-only).  
- On registration, prompt: “Are you [shadow name] in [group]?” for matches.  
- Merge shadow into member, remove shadow, update X/Y.

---

### Gap 5: Member removal (kick) and re-join

**Missing:** No explicit kick flow or blocked-user list.

**Why it’s a real problem:**  
- Admin needs to remove a toxic or spam member.  
- Spec only describes “leave,” not “remove.”  
- Without block list, kicked user can re-join with same link.

**Fix:** Admin can remove members. Add `blockedUserIds` on group. Re-join rejected for blocked users. Re-join allowed for non-blocked users who left.

---

### Gap 6: Account deletion and groups

**Missing:** No behavior for account deletion.

**Why it’s a real problem:**  
- User deletes account; membership doc stays.  
- Group shows a ghost member; X/Y becomes wrong.  
- If they were admin, group is orphaned.

**Fix:** On account deletion: remove from all groups, recompute X/Y. If admin, run admin succession before final removal.

---

### Gap 7: Group membership cardinality (one vs many)

**Missing:** No rule on how many groups a user can join or create.

**Why it’s a real problem:**  
- Spec implies “one group” but doesn’t state it.  
- Real use: family + mosque group + friends.  
- If only one group is allowed, product will feel limited; if unlimited, UI and scope explode.

**Fix:** Decide for v1: either “one group per user” or “up to 2–3 groups” with explicit rationale. If multiple groups, define primary/default group and switching UI.

---

### Gap 8: X/Y computation and scale

**Missing:** No schema or algorithm for computing “X of Y prayed today.”

**Why it’s a real problem:**  
- Naive approach: query all members, then each member’s prayer logs = N+1 queries per view.  
- With 50+ members, this is slow and costly.  
- No aggregates → poor UX and high Firestore cost.

**Fix:** Add `groups/{groupId}/daily/{date}` (or equivalent) aggregate doc updated on each prayer log. X/Y reads from this. Document in data model.

---

## 2. Edge Cases & Failure Modes

### Edge case 1: Network fails during join

| Field | Detail |
|-------|--------|
| **Trigger** | User taps join; network dies before Firestore write. |
| **User impact** | Spinner hangs; user retries; risk of duplicate membership or confusing errors. |
| **Fix** | Idempotent join: check if already member; retry with backoff; show “Retry join” if failure; store pending join locally and retry when online. |

---

### Edge case 2: Admin leaves, no other members

| Field | Detail |
|-------|--------|
| **Trigger** | Admin leaves and there are no other members. |
| **User impact** | Group has no admin; invite link still works; group is unusable. |
| **Fix** | If admin leaves and no members remain, auto-dissolve group. If admin leaves and others exist, force selecting new admin or dissolving. |

---

### Edge case 3: Duplicate shadow members

| Field | Detail |
|-------|--------|
| **Trigger** | Admin adds “Ahmad” twice (e.g. two kids with same name). |
| **User impact** | Y is inflated; X/Y misleading. |
| **Fix** | Uniqueness: same name in same group → warning or block. Optional: add disambiguator (e.g. “Ahmad (older)”, “Ahmad (younger)”). |

---

### Edge case 4: Member leaves and re-joins

| Field | Detail |
|-------|--------|
| **Trigger** | Member leaves, later opens invite link again. |
| **User impact** | Unclear if they re-join or see “already member.” |
| **Fix** | Allow re-join via same link. Personal history tied to user, not membership. Count in X/Y only after re-join. |

---

### Edge case 5: Deep link with app not installed

| Field | Detail |
|-------|--------|
| **Trigger** | User opens invite link on device without the app. |
| **User impact** | 404 or store redirect; invite context lost. |
| **Fix** | Web fallback: `qurb.app/join/CODE` shows “Download app to join” and store links. Use App Links / Universal Links to pass code into app on install. |

---

### Edge case 6: Empty group (admin only)

| Field | Detail |
|-------|--------|
| **Trigger** | Admin creates group, shares link, no one joins. |
| **User impact** | “0/1 prayed today” — confusing or demotivating. |
| **Fix** | No auto-delete. Clear empty state: “Invite members to see group summary.” Option to dissolve group. |

---

## 3. Design Decisions That Need Justification

### Decision 1: Drawer vs bottom nav for Family

| Aspect | Choice | Alternatives | Recommendation |
|--------|--------|--------------|----------------|
| **What** | Family entry in Drawer | Family as separate tab in bottom nav | If family is a core pillar, bottom nav is better. |
| **Why it matters** | Drawer = secondary; bottom nav = primary. | Drawer keeps current structure; nav requires layout change. | Define product stance: is family core or secondary? If core, use bottom nav. |

---

### Decision 2: Invite mechanism (code vs link vs QR)

| Aspect | Choice | Alternatives | Recommendation |
|--------|--------|--------------|----------------|
| **What** | Code + link + QR | Link-only (user preference) | Use link as primary; code as fallback when deep link fails. |
| **Why it matters** | Link-only fails when app not installed or deep link broken. | Code-only is tedious to share. | Implement link first; derive short code from same ID; QR optional. |

---

### Decision 3: Single group vs multiple groups per user

| Aspect | Choice | Alternatives | Recommendation |
|--------|--------|--------------|----------------|
| **What** | Implicit “one group” | Explicit “up to 2–3 groups” | Decide explicitly. |
| **Why it matters** | One group is simpler; multiple groups match real usage (family + mosque + friends). | No stated rationale. | Recommend: v1 allow 1 group to reduce scope; plan v2 for 2–3 groups if validated. |

---

### Decision 4: X/Y with no names vs optional names

| Aspect | Choice | Alternatives | Recommendation |
|--------|--------|--------------|----------------|
| **What** | Only “X/Y prayed” (no names) | Optional “who prayed” (no times) | Privacy-first is good; some families want names for motivation. |
| **Why it matters** | Pure aggregate = max privacy. Names = more social pressure / motivation. | Not explored in spec. | Keep v1 aggregate-only. Add optional “show who prayed (no times)” as group setting in v2. |

---

## 4. Prioritized Action List

| Priority | Issue | Effort | Impact |
|----------|-------|--------|--------|
| **P0** | Auth required before join; pending-invite flow | Medium | Blocker — join cannot work without it |
| **P0** | Admin succession / orphan handling | Medium | Blocker — groups become broken otherwise |
| **P0** | Member removal (kick) and block list | Low | Blocker — needed for moderation |
| **P0** | Account deletion → remove from groups + admin succession | Low | Blocker — data integrity |
| **P1** | Invite expiry and/or max uses | Low | High — prevents abuse |
| **P1** | X/Y aggregate document (scale) | Medium | High — performance at scale |
| **P1** | Explicit one-group vs multi-group policy | Low | High — affects UX and roadmap |
| **P1** | Network failure / retry for join | Low | High — common edge case |
| **P1** | Deep link fallback when app not installed | Medium | High — first-touch experience |
| **P2** | Shadow → real member migration | Medium | Medium — can defer to v2 |
| **P2** | Duplicate shadow name prevention | Low | Medium — polish |
| **P2** | Drawer vs bottom nav | Low | Medium — product positioning |
| **P2** | Link-first vs code-first | Low | Low — implementation detail |

---

## 5. Final Verdict

**Score: 5/10**

### What works
- Clear privacy stance (aggregate only).
- Unified model for family, guided, friends.
- Shadow members for non-users.
- Sensible Firestore structure (admin, members).

### What blocks implementation
1. **Auth and join flow** — join cannot be implemented without auth + pending-invite.
2. **Admin succession** — no handling for admin leaving or dying.
3. **Moderation** — no kick or block.
4. **Account deletion** — undefined behavior for groups.
5. **X/Y computation** — no scalable design.

### What must change before implementation
- Add **P0 items** to spec: auth-before-join, admin succession, kick + block, account deletion.
- Define **X/Y aggregation** in the data model.
- Make **group cardinality** explicit (one vs multiple groups).
- Add **invite policy** (expiry / max uses) for v1 or document as v2.

### What can wait
- Shadow → real migration (v2).
- Invite expiry / limits (can ship v1 with permanent links).
- Drawer vs nav placement (implementation detail if scope is fixed).

---

**Summary:** The spec has solid ideas and good privacy choices, but it is not implementation-ready. Critical flows (auth, admin lifecycle, moderation, deletion, scaling) are missing. Address P0 items and X/Y design before development; treat the rest as P1/P2 backlog.
