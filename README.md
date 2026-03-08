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

*SecretLens — Powered by Gemini AI*
