# SecretLens

> A developer-facing security guardrail that intercepts commits containing hardcoded secrets, remediates them automatically, and generates safe retrieval code.

---

## What It Does

When a developer runs `git commit`, the detection engine scans staged files for secrets (API keys, private keys, credentials). If any are found:

1. The commit is **blocked**
2. The UI surfaces every finding with file, line, severity, and a masked preview
3. The developer can review details, **automatically store secrets in AWS Secrets Manager**, and get generated retrieval code to drop back into their source
4. Once remediated, the commit proceeds cleanly — no secret ever lands in git history

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Developer Machine                       │
│                                                              │
│   git commit                                                 │
│       │                                                      │
│       ▼                                                      │
│  ┌─────────────────────┐                                     │
│  │  Detection Engine   │  ← scans staged files with regexes │
│  │  (pre-commit hook)  │    / Gemini AI pattern matching     │
│  └──────────┬──────────┘                                     │
│             │  secrets found                                 │
│             ▼                                                │
│  ┌─────────────────────┐                                     │
│  │   SecretLens UI     │  ← Flutter app (this repo)         │
│  │  (Flutter / Dart)   │                                     │
│  └──────────┬──────────┘                                     │
│             │  POST /store-secret                            │
│             ▼                                                │
│  ┌─────────────────────┐                                     │
│  │  Remediation API    │  ← backend (future)                │
│  └──────────┬──────────┘                                     │
│             │                                                │
│             ▼                                                │
│  ┌─────────────────────┐                                     │
│  │  AWS Secrets Manager│  ← encrypted secret storage        │
│  └──────────┬──────────┘                                     │
│             │  generated ARN                                 │
│             ▼                                                │
│  ┌─────────────────────┐                                     │
│  │  Generated Code     │  ← shown in-app, ready to paste    │
│  │  (Python / JS / sh) │                                     │
│  └─────────────────────┘                                     │
└─────────────────────────────────────────────────────────────┘
```

---

## Flutter App Architecture

Feature-first layout with a clean separation of domain, data, and presentation layers.

```
lib/
├── main.dart                          # ProviderScope entry point
│
├── core/
│   ├── constants/
│   │   └── app_colors.dart            # Design system colour tokens
│   └── theme/
│       └── app_theme.dart             # Dark ThemeData configuration
│
└── features/
    └── commit_block/
        │
        ├── domain/
        │   └── models/
        │       └── finding.dart       # Finding, Severity, FixStatus
        │
        └── presentation/
            ├── providers/
            │   └── commit_block_provider.dart  # State + Notifier
            │
            ├── widgets/
            │   ├── finding_tile.dart           # Single secret card
            │   ├── risk_warning_box.dart        # Amber/red alert panel
            │   └── footer_branding.dart         # SecretLens + Gemini badge
            │
            └── screens/
                ├── commit_blocked_screen.dart       # [1] Main blocked view
                ├── findings_detail_screen.dart      # [2] Per-finding detail
                ├── fix_issues_progress_screen.dart  # [3] Animated fix flow
                ├── secret_saved_screen.dart         # [4] Success + ARNs
                └── generated_snippet_screen.dart    # [5] Copy-ready code
```

---

## Screen Flow

```
[1] CommitBlockedScreen
      │
      ├── REVIEW FINDINGS ──────────► [2] FindingsDetailScreen
      │                                     (tabbed, per-finding detail,
      │                                      severity badge, masked value,
      │                                      impact description)
      │
      ├── FIX ALL ISSUES ───────────► [3] FixIssuesProgressScreen
      │                                     (animated pulsing shield,
      │                                      sequential secret processing,
      │                                      live progress bar)
      │                                          │
      │                                          ▼
      │                                    [4] SecretSavedScreen
      │                                          (green checkmark,
      │                                           stored ARNs listed,
      │                                           what-happened summary)
      │                                               │
      │                                               ▼
      │                                         [5] GeneratedSnippetScreen
      │                                               (language-tagged blocks,
      │                                                copy button per snippet,
      │                                                reminder to remove originals)
      │
      └── COMMIT ANYWAY ────────────► Confirmation dialog → Override state
```

---

## State Management

**Riverpod** — `StateNotifierProvider<CommitBlockNotifier, CommitBlockState>`

### `CommitBlockState`

| Field              | Type              | Description                                   |
|--------------------|-------------------|-----------------------------------------------|
| `findings`         | `List<Finding>`   | All detected secrets for this commit          |
| `fixInProgress`    | `bool`            | True while `fixAllIssues()` is running        |
| `fixCompleted`     | `bool`            | True after all secrets are stored             |
| `commitOverridden` | `bool`            | True if developer chose to commit anyway      |
| `currentFixIndex`  | `int`             | Index of the secret currently being processed |
| `fixStatusMessage` | `String?`         | Live status label shown during the fix flow   |

**Computed getters:**
- `riskLevel` — derives `CRITICAL / HIGH / MEDIUM / LOW` from finding severities
- `isBlocked` — `true` while neither fixed nor overridden
- `unfixedCount` / `fixedCount` — drive progress indicators

### `CommitBlockNotifier` methods

| Method           | What it does                                                                       |
|------------------|------------------------------------------------------------------------------------|
| `fixAllIssues()` | Async loop — processes each secret, emits granular state updates, stores ARN + generated code per finding |
| `commitAnyway()` | Sets `commitOverridden = true` (logged for audit)                                  |
| `reset()`        | Restores to initial mock state (demo / test use)                                   |

---

## Domain Model

### `Finding`

```
Finding
 ├── id               String     unique identifier
 ├── secretType       String     e.g. "AWS Access Key"
 ├── file             String     relative path  e.g. "src/config.js"
 ├── line             int        line number in that file
 ├── severity         Severity   critical | high | medium | low
 ├── maskedValue      String     redacted preview shown in UI
 ├── language         String?    "javascript" | "python" | "shell"
 ├── fixStatus        FixStatus  unfixed | inProgress | stored | failed
 ├── storedSecretArn  String?    ARN assigned after AWS storage
 └── generatedCode    String?    retrieval snippet, set after fix
```

### Enums

```
Severity:  critical → red    (#FF3B3B)
           high     → orange (#FF6B35)
           medium   → amber  (#FFB800)
           low      → blue   (#4D9FFF)

FixStatus: unfixed | inProgress | stored | failed
```

---

## Mock Data (current)

The app ships with three hardcoded findings that simulate a real detection result:

| # | Secret Type       | File               | Line | Severity | Language   |
|---|-------------------|--------------------|------|----------|------------|
| 1 | AWS Access Key    | `src/config.js`    | 23   | CRITICAL | JavaScript |
| 2 | RSA Private Key   | `backend/auth.py`  | 7    | CRITICAL | Python     |
| 3 | Stripe API Secret | `.env`             | 12   | HIGH     | Shell      |

Generated code templates are inline in `commit_block_provider.dart` and produce AWS SDK v3 (JS), boto3 (Python), or AWS CLI (shell) snippets pointing to the stored secret ARN.

---

## Design System

Dark security aesthetic throughout. All tokens live in `lib/core/constants/app_colors.dart`.

| Token           | Hex       | Usage                              |
|-----------------|-----------|------------------------------------|
| `background`    | `#080810` | Scaffold background                |
| `surface`       | `#10101C` | AppBar, section backgrounds        |
| `card`          | `#16162A` | Finding cards                      |
| `codeBlock`     | `#0D0D1A` | Inline code backgrounds            |
| `danger`        | `#FF3B3B` | BLOCKED header, CRITICAL badge     |
| `warning`       | `#FFB800` | Risk warning box, HIGH severity    |
| `success`       | `#00D97E` | Secured badge, progress complete   |
| `info`          | `#4D9FFF` | Gemini AI badge, LOW severity      |
| `textCode`      | `#7EFFA0` | Monospace code text                |
| `textSecondary` | `#8A8AA8` | Subtitles, metadata                |

---

## Tech Stack

| Layer         | Technology                      |
|---------------|---------------------------------|
| UI Framework  | Flutter (Dart)                  |
| State         | flutter_riverpod `^2.6.1`       |
| Platforms     | iOS · Android · macOS · Web     |
| Cloud Storage | AWS Secrets Manager (stubbed)   |
| AI Detection  | Gemini AI (planned integration) |

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on your device / simulator
flutter run

# Static analysis
flutter analyze
```

**Requirements:** Flutter SDK ≥ 3.x · Dart SDK ≥ 3.x

---

## Current State

| Area                         | Status           |
|------------------------------|------------------|
| CommitBlockedScreen UI       | ✅ Complete      |
| FindingsDetailScreen         | ✅ Complete      |
| FixIssuesProgressScreen      | ✅ Complete      |
| SecretSavedScreen            | ✅ Complete      |
| GeneratedSnippetScreen       | ✅ Complete      |
| Riverpod state management    | ✅ Complete      |
| Mock detection data          | ✅ 3 findings    |
| Real detection engine hook   | 🔲 Planned       |
| Remediation API integration  | 🔲 Planned       |
| AWS Secrets Manager calls    | 🔲 Planned       |
| Gemini AI scanning           | 🔲 Planned       |
| Secret history dashboard     | 🔲 Planned       |
| Repo security score screen   | 🔲 Planned       |

---

## Planned API Endpoints

```
POST /scan              → trigger secret scan on staged files
POST /store-secret      → store a found secret in AWS Secrets Manager
POST /generate-snippet  → return language-specific retrieval code
GET  /history           → fetch previously remediated secrets
```

---

## Data Flow

This section documents how data moves through the Flutter app from ingestion to UI rendering and user-triggered actions. No backend or scanning engine exists yet — the app is driven by mock data. This document describes both the current internal flow and exactly where real API calls will slot in once the backend is built.

---

### 1. High-Level Data Flow

```
  Data Source                  Provider Layer                   UI Layer
  ─────────────────            ──────────────────────────       ──────────────────────────────
                               CommitBlockNotifier
  [Mock findings]  ──────────► initializes with                 CommitBlockedScreen
  [Future: POST /scan]         List<Finding>                    ├─ reads state.findings
                                     │                          ├─ reads state.riskLevel
                                     │ state emitted            ├─ reads state.findings.length
                                     ▼                          │
                               CommitBlockState ◄── ref.watch ──┤
                                     │                          ├─ FindingsDetailScreen
                                     │                          │   reads findings[id]
                                     │                          │   reads finding.fixStatus
                                     │                          │   reads finding.storedSecretArn
                                     │                          │
                               fixAllIssues()                   ├─ FixIssuesProgressScreen
                                     │                          │   reads currentFixIndex
                                     │ emits on each phase      │   reads fixedCount
                                     ▼                          │   reads fixStatusMessage
                               Finding.copyWith()               │   reads finding.fixStatus
                               fixStatus → stored               │
                               storedSecretArn = ARN            ├─ SecretSavedScreen
                               generatedCode = snippet          │   reads findings where
                                     │                          │   storedSecretArn != null
                                     │                          │
                                     │                          └─ GeneratedSnippetScreen
                                     │                              reads findings where
                                     └──────────────────────────►   generatedCode != null
```

---

### 2. Data Ingestion

#### Current: Mock Data

There is no API call at startup. `CommitBlockNotifier` initialises its state directly from a hardcoded list defined at the top of `commit_block_provider.dart`:

```dart
final _mockFindings = [
  const Finding(
    id: 'finding-001',
    secretType: 'AWS Access Key',
    file: 'src/config.js',
    line: 23,
    severity: Severity.critical,
    maskedValue: 'AKIA••••••••••••WXYZ',
    language: 'javascript',
  ),
  // ... two more findings
];

class CommitBlockNotifier extends StateNotifier<CommitBlockState> {
  CommitBlockNotifier()
      : super(CommitBlockState(findings: List.from(_mockFindings)));
}
```

The notifier is instantiated once, lazily, the first time any widget calls `ref.watch(commitBlockProvider)`. The `ProviderScope` at the root of the widget tree in `main.dart` owns the provider lifetime.

#### Future: `POST /scan` Response

When the detection engine is integrated, `CommitBlockNotifier` will accept the scan payload and convert it into `Finding` objects before setting initial state. The expected JSON shape from `POST /scan` is:

```json
{
  "commitHash": "a3f8c21",
  "repoPath": "/Users/dev/myproject",
  "blocked": true,
  "findings": [
    {
      "id": "finding-001",
      "secretType": "AWS Access Key",
      "file": "src/config.js",
      "line": 23,
      "severity": "critical",
      "maskedValue": "AKIA••••••••••••WXYZ",
      "language": "javascript"
    },
    {
      "id": "finding-002",
      "secretType": "RSA Private Key",
      "file": "backend/auth.py",
      "line": 7,
      "severity": "critical",
      "maskedValue": "-----BEGIN RSA PRIVATE KEY-----\nMIIEow••••••••••••",
      "language": "python"
    }
  ]
}
```

Each item in `findings` maps directly to a `Finding` model. The `severity` string `"critical" | "high" | "medium" | "low"` must be parsed into the `Severity` enum. `maskedValue` is computed server-side — the raw secret is never sent to the client.

---

### 3. Domain Model: `Finding`

`Finding` is a plain immutable Dart class in `lib/features/commit_block/domain/models/finding.dart`. It is the only domain object in the app and is the unit of data that flows through every layer.

```
Finding (immutable)
 ├── id               String     — stable identifier used for tab selection and ARN path
 ├── secretType       String     — human-readable label e.g. "Stripe API Secret"
 ├── file             String     — repo-relative file path
 ├── line             int        — 1-based line number within that file
 ├── severity         Severity   — drives colour, badge text, riskLevel computation
 ├── maskedValue      String     — redacted preview; never the real secret
 ├── language         String?    — determines which code template is generated
 ├── fixStatus        FixStatus  — lifecycle state of this finding
 ├── storedSecretArn  String?    — null until POST /store-secret succeeds
 └── generatedCode    String?    — null until _generateRetrievalCode() runs
```

**`FixStatus` lifecycle:**

```
unfixed ──► inProgress ──► stored
                │
                └──► failed   (reserved; not yet triggered in UI)
```

**Immutability via `copyWith`:**

`Finding` is never mutated in place. Every state transition produces a new `Finding` instance via `copyWith`, which only allows updating `fixStatus`, `storedSecretArn`, and `generatedCode` — the three fields that change during the fix flow. The identity fields (`id`, `secretType`, `file`, `line`, `severity`, `maskedValue`, `language`) are permanently fixed at construction time.

```dart
// Example: transitioning a finding to in-progress
updatedFindings[i] = updatedFindings[i].copyWith(
  fixStatus: FixStatus.inProgress,
);

// Example: transitioning to stored after API call
updatedFindings[i] = updatedFindings[i].copyWith(
  fixStatus: FixStatus.stored,
  storedSecretArn: 'arn:aws:secretsmanager:...',
  generatedCode: '...',
);
```

**`Severity` extension:**

`SeverityExt` (on the `Severity` enum) provides `.label` (string for badges) and `.colorValue` (ARGB int for `Color()`), keeping colour logic in the domain layer rather than scattered across widgets.

---

### 4. Provider Layer

#### `CommitBlockState`

`CommitBlockState` is the single source of truth for the entire feature. It is immutable — every mutation returns a new instance via `copyWith`.

```dart
class CommitBlockState {
  final List<Finding> findings;       // core data — never mutated directly
  final bool fixInProgress;           // true during fixAllIssues() async loop
  final bool fixCompleted;            // true once all findings reach FixStatus.stored
  final bool commitOverridden;        // true if developer dismissed the block
  final int currentFixIndex;          // which finding is being processed right now
  final String? fixStatusMessage;     // live human-readable phase label
}
```

**Computed getters** derive secondary values from the primary fields on every rebuild — no stale derived state:

| Getter         | Logic                                                                   | Consumed by                                        |
|----------------|-------------------------------------------------------------------------|----------------------------------------------------|
| `riskLevel`    | Checks severities in priority order: critical → high → medium → low     | `RiskWarningBox`, `CommitBlockedScreen` badge      |
| `isBlocked`    | `!commitOverridden && !fixCompleted`                                     | `CommitBlockedScreen` branch logic                 |
| `unfixedCount` | `findings.where(f => f.fixStatus == FixStatus.unfixed).length`          | `FindingsDetailScreen` unresolved counter          |
| `fixedCount`   | `findings.where(f => f.fixStatus == FixStatus.stored).length`           | `FixIssuesProgressScreen` progress bar numerator   |

#### `CommitBlockNotifier`

The notifier exposes three public methods. All state updates flow exclusively through these — no widget writes to state directly.

---

### 5. `fixAllIssues()` — Async State Machine

This is the most data-intensive operation in the app. It runs as a sequential `async` loop and emits multiple discrete state snapshots per finding so the UI can animate each phase in real time.

**Phase sequence per finding:**

```
Phase 0 — mark in-progress
  state.findings[i].fixStatus = FixStatus.inProgress
  state.currentFixIndex       = i
  state.fixStatusMessage      = 'Analyzing <secretType>...'
  ↓ await 800ms

Phase 1 — storage phase label
  state.fixStatusMessage      = 'Storing in AWS Secrets Manager...'
  [Future: POST /store-secret called here]
  ↓ await 1000ms

Phase 2 — code generation label
  state.fixStatusMessage      = 'Generating retrieval code...'
  [Future: POST /generate-snippet called here]
  ↓ await 600ms

Phase 3 — mark stored
  state.findings[i].fixStatus     = FixStatus.stored
  state.findings[i].storedSecretArn = 'arn:aws:...'
  state.findings[i].generatedCode   = <generated snippet>
  state.currentFixIndex             = i + 1
```

After the loop completes across all findings:

```
state.fixInProgress    = false
state.fixCompleted     = true
state.fixStatusMessage = 'All secrets secured'
```

`FixIssuesProgressScreen` then auto-navigates to `SecretSavedScreen` via `Navigator.pushReplacement`.

**Why multiple emits per finding?**
Each `state = state.copyWith(...)` call triggers a rebuild of every widget that has called `ref.watch(commitBlockProvider)`. Emitting separately for the label change (`fixStatusMessage`) and for the data change (`findings[i].fixStatus`) gives the progress screen smooth, granular animation without batching.

**How `_ProgressItem` determines its display state:**

```dart
final isCurrent = index == state.currentFixIndex && state.fixInProgress;
final isDone    = finding.fixStatus == FixStatus.stored;
final isPending = !isDone && index > state.currentFixIndex;
```

This drives three distinct visual states — spinner (current), checkmark (done), hollow circle (pending) — purely from provider state, with no local widget state involved.

---

### 6. Screen-by-Screen Data Consumption

#### `CommitBlockedScreen`

```
ref.watch(commitBlockProvider)
  │
  ├── state.commitOverridden  → if true, replaces entire scaffold with override view
  ├── state.findings          → ListView.builder itemCount + Finding passed to FindingTile
  ├── state.findings.length   → subtitle "N secrets detected..."
  ├── state.riskLevel         → RiskWarningBox(riskLevel:)
  └── state.findings.length   → RiskWarningBox(findingCount:)

User actions:
  "REVIEW FINDINGS"  → Navigator.push(FindingsDetailScreen())          // read-only, no state change
  "FIX ALL ISSUES"   → Navigator.push(FixIssuesProgressScreen())       // triggers fixAllIssues()
  "COMMIT ANYWAY"    → dialog → ref.read(...notifier).commitAnyway()   // sets commitOverridden=true
  tap FindingTile    → Navigator.push(FindingsDetailScreen(selectedFindingId: finding.id))
```

#### `FindingsDetailScreen`

Accepts an optional `selectedFindingId` constructor argument. If provided (tap from list), that finding's tab is pre-selected. If absent (tap from button), defaults to `findings.first`.

```
ref.watch(commitBlockProvider)
  │
  ├── state.findings          → tab strip + active finding lookup by id
  ├── state.unfixedCount      → AppBar badge "N UNRESOLVED"
  └── activeFinding           → _FindingDetailCard receives the full Finding object
        ├── finding.secretType, .file, .line     → detail rows
        ├── finding.severity                     → badge colour + label
        ├── finding.maskedValue                  → _CopyableCodeBlock
        ├── finding.fixStatus == stored          → conditionally shows ARN block / impact panel
        └── finding.storedSecretArn              → _CopyableCodeBlock (green, post-fix only)
```

Tab selection is local `setState` on `_activeFindingId` — it is pure navigation state, not persisted to the provider.

#### `FixIssuesProgressScreen`

This screen owns the fix lifecycle. On first frame it calls `fixAllIssues()` and then watches the provider for every subsequent state emission.

```
initState → WidgetsBinding.addPostFrameCallback
  └── _startFix()
        └── ref.read(commitBlockProvider.notifier).fixAllIssues()  // drives all state
              └── on completion → Navigator.pushReplacement(SecretSavedScreen)

ref.watch(commitBlockProvider)
  │
  ├── state.fixStatusMessage   → subtitle label beneath "SECURING SECRETS"
  ├── state.findings           → ListView.builder, one _ProgressItem per finding
  ├── state.currentFixIndex    → determines which item gets spinner
  ├── state.fixInProgress      → combined with index to derive isCurrent
  ├── state.fixedCount         → LinearProgressIndicator value numerator
  └── finding.fixStatus        → isDone / isCurrent / isPending per item
        finding.storedSecretArn → shown inside _ProgressItem once stored
```

`PopScope(canPop: false)` prevents back navigation during processing.

#### `SecretSavedScreen`

Read-only success view. Derives its display data by filtering the findings list.

```
ref.watch(commitBlockProvider)
  │
  └── state.findings.where(f => f.storedSecretArn != null)
        └── for each stored finding:
              finding.secretType      → card label
              finding.storedSecretArn → monospace ARN display

User actions:
  "VIEW GENERATED CODE" → Navigator.push(GeneratedSnippetScreen())
  "DONE" / close        → Navigator.popUntil(route.isFirst)  // back to CommitBlockedScreen
```

#### `GeneratedSnippetScreen`

Read-only code display. Derives its list by filtering for findings that have completed code generation.

```
ref.watch(commitBlockProvider)
  │
  └── state.findings.where(f => f.generatedCode != null)
        └── for each finding:
              finding.secretType    → card header
              finding.file          → subtitle
              finding.language      → language badge colour + label
              finding.generatedCode → SelectableText in code block
              finding.storedSecretArn → footer ARN

Local state (setState, not provider):
  _copiedIds: Set<String>  → tracks which snippet copy buttons show "COPIED"
                             resets per id after 2 seconds via Future.delayed
```

---

### 7. User Action → State Mapping

| User Action                    | Navigator Effect                     | Provider Effect                                                    |
|--------------------------------|--------------------------------------|--------------------------------------------------------------------|
| Tap "REVIEW FINDINGS"          | Push `FindingsDetailScreen`          | None                                                               |
| Tap a `FindingTile`            | Push `FindingsDetailScreen(id:)`     | None                                                               |
| Switch tab in detail screen    | None                                 | None (local setState only)                                         |
| Tap "FIX ALL ISSUES"           | Push `FixIssuesProgressScreen`       | `fixAllIssues()` runs — emits ~4 states per finding               |
| Fix loop completes             | `pushReplacement(SecretSavedScreen)` | `fixCompleted=true`, `fixInProgress=false`                         |
| Tap "VIEW GENERATED CODE"      | Push `GeneratedSnippetScreen`        | None                                                               |
| Tap "COMMIT IS CLEAR"          | `popUntil(isFirst)`                  | None                                                               |
| Tap "COMMIT ANYWAY"            | Opens `AlertDialog`                  | None yet                                                           |
| Confirm "COMMIT ANYWAY"        | `pop()` dialog                       | `commitAnyway()` → `commitOverridden=true`                         |
| Tap "RESTART DEMO" (override)  | None                                 | `reset()` → restores all 3 mock findings to `FixStatus.unfixed`    |

---

### 8. API Integration Points

The four planned endpoints slot into the flow at specific locations. No repository or datasource layer exists yet — when built, each endpoint belongs in `lib/features/commit_block/data/` and is called from `CommitBlockNotifier`.

#### `POST /scan`

**Trigger:** Called by the pre-commit hook or on app startup, before `CommitBlockedScreen` is shown.
**Slot:** Replaces the hardcoded `_mockFindings` list in `CommitBlockNotifier`.

```
Request body:
{
  "repoPath": "/Users/dev/project",
  "stagedFiles": ["src/config.js", "backend/auth.py", ".env"]
}

Response body:
{
  "commitHash": "a3f8c21",
  "blocked": true,
  "findings": [
    {
      "id":          "finding-001",
      "secretType":  "AWS Access Key",
      "file":        "src/config.js",
      "line":        23,
      "severity":    "critical",
      "maskedValue": "AKIA••••••••••••WXYZ",
      "language":    "javascript"
    }
  ]
}
```

`severity` string → `Severity` enum via a `fromString` factory (to be added to `finding.dart`).
`masked_value` is server-computed; the raw secret never leaves the detection engine.

---

#### `POST /store-secret`

**Trigger:** Called once per finding inside the `fixAllIssues()` loop, during Phase 1.
**Slot:** Replaces the hardcoded ARN string `'arn:aws:secretsmanager:us-east-1:123456789012:secret:secretlens/${finding.id}'`.

```
Request body:
{
  "findingId":  "finding-001",
  "secretType": "AWS Access Key",
  "file":       "src/config.js",
  "line":       23
}

Response body:
{
  "findingId": "finding-001",
  "arn":       "arn:aws:secretsmanager:us-east-1:123456789012:secret:secretlens/finding-001-a1b2c3"
}
```

The `arn` from the response is stored in `Finding.storedSecretArn` via `copyWith` and immediately rendered in `FixIssuesProgressScreen` and `SecretSavedScreen`.

---

#### `POST /generate-snippet`

**Trigger:** Called once per finding inside the `fixAllIssues()` loop, during Phase 2, after the ARN is known.
**Slot:** Replaces `_generateRetrievalCode()` in `CommitBlockNotifier`.

```
Request body:
{
  "findingId":  "finding-001",
  "arn":        "arn:aws:secretsmanager:us-east-1:123456789012:secret:secretlens/finding-001-a1b2c3",
  "language":   "javascript"
}

Response body:
{
  "findingId": "finding-001",
  "language":  "javascript",
  "snippet":   "const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');\n\n..."
}
```

The `snippet` is stored in `Finding.generatedCode` via `copyWith` and rendered verbatim in `GeneratedSnippetScreen` inside a `SelectableText`.

---

#### `GET /history`

**Trigger:** On load of a future "Secret History" screen (not yet built).
**Slot:** Will power a new screen (`SecretHistoryScreen`) and a new provider (`secretHistoryProvider`), separate from `commitBlockProvider`.

```
Response body:
{
  "entries": [
    {
      "findingId":       "finding-001",
      "secretType":      "AWS Access Key",
      "file":            "src/config.js",
      "storedAt":        "2026-03-08T14:22:00Z",
      "arn":             "arn:aws:secretsmanager:...",
      "commitHash":      "a3f8c21",
      "repoPath":        "/Users/dev/project"
    }
  ]
}
```

---

### 9. Where the Data Layer Will Live

When backend integration is added, the recommended locations following the existing feature-first architecture are:

```
lib/features/commit_block/
  ├── data/
  │   ├── repositories/
  │   │   └── commit_block_repository.dart   # interface + impl
  │   └── datasources/
  │       └── secrets_api_datasource.dart    # HTTP calls via dio / http
  └── domain/
      └── usecases/                          # optional, if logic grows complex
          ├── scan_commit_usecase.dart
          ├── store_secret_usecase.dart
          └── generate_snippet_usecase.dart
```

`CommitBlockNotifier` will receive the repository via constructor injection, keeping it testable without a real network:

```dart
class CommitBlockNotifier extends StateNotifier<CommitBlockState> {
  final CommitBlockRepository _repository;

  CommitBlockNotifier(this._repository)
      : super(const CommitBlockState(findings: []));
}

final commitBlockProvider =
    StateNotifierProvider<CommitBlockNotifier, CommitBlockState>(
  (ref) => CommitBlockNotifier(ref.watch(commitBlockRepositoryProvider)),
);
```

---

*SecretLens — Powered by Gemini AI*
