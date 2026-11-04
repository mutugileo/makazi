# PropMgtApp Agent Rules & Guidelines

`PropMgtApp` is the tenant-facing cross-platform mobile application for Makazi, built with **Flutter** and **Riverpod**.

---

## Architectural Rules

### 1. Pure UI & Riverpod State Flow
- UI widgets must be declarative, side-effect free, and driven exclusively by Riverpod state.
- Widgets may only read immutable state and dispatch user intents (e.g. `notifier.submitRepair()`).
- All side effects live in Notifiers, Use Cases, or Repositories.
- Loading states must use skeleton or shimmer surfaces, never solitary spinners by default.

### 2. Feature-First Boundaries
- Code is organized strictly by feature:
  `lib/features/<feature>/{data, domain, presentation}`
- Features must not import directly from peer features; shared domain logic lives exclusively in `lib/core/`.

### 3. Mobile Viewport & Typography Rules
- **Font**: Must use project's selected `Lexend` typography through shared text theme tokens. Never hardcode one-off font families.
- **Mobile Width (390px)**: Always verify text layout and card padding on narrow devices (390px iPhone/Android). Use `Expanded`, `Flexible`, `maxLines`, and `TextOverflow.ellipsis` to prevent horizontal pixel overflow.
- **Kenyan Phone Numbers**: Must normalize phone numbers using `normalizeKenyanPhone()` to ensure consistent `+254` / local Kenyan mobile representation.
- **No `e.g.` hints**: Hints must provide clear guidance (e.g., `'Enter a valid 10-digit mobile number starting with 07 or 01'`).

### 4. Required Verification Protocol
Before declaring any Flutter work complete:
```sh
dart format <changed dart files>
flutter analyze
flutter test
```
All tests must pass with 0 analyze warnings.
