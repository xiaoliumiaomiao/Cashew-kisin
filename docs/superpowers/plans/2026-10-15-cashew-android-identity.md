# Cashew Android Identity Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Change this personal fork's Android application identity to `com.kisin.cashew`, retaining `Cashew` as its display name and all existing functionality.

**Architecture:** Change the explicit Gradle Application ID, namespace and five Kotlin package declarations together. The installed home_widget plugin resolves provider classes from context.packageName plus the short class name; synchronizing packages preserves all widget calls without changing their behavior. Require legitimate service credentials; never fabricate Firebase configuration or bypass services to force an APK.

**Tech Stack:** Flutter 3.19.6, Dart 3.3.4, Android Gradle Plugin 8.3.2, Kotlin 1.9.22, project-local Android SDK/JDK.

## Global Constraints

- Official application ID: `com.budget.tracker_app`; custom application ID: `com.kisin.cashew`; display name: `Cashew`.
- Preserve all UI, business logic, database schema and existing customizations.
- Source changes and local builds only. No deployment, phone installation/uninstallation, app-data changes, ledger access or private data uploads.
- Never rename the original Firebase client's package name to claim a valid new client.
- Stop credential-dependent work and report the missing legitimate configuration; do not remove features to bypass errors.
- Preserve Git history and record a rollback ref before edits.

## Task 1: Minimal source identity configuration

**Files:**
- Modify: `budget/android/app/build.gradle`, Application ID, namespace and explanatory comments only.
- Modify: `budget/android/app/src/main/kotlin/com/example/budget/{MainActivity,PlusWidgetProvider,TransferWidgetProvider,NetWorthWidgetProvider,NetWorthPlusWidgetProvider}.kt`, package declaration only.
- Inspect: all `budget/android/app/src/**/AndroidManifest.xml`, Kotlin widget/activity sources, Dart widget/notification/service configuration.

- [x] Verify a clean working tree at commit `824c1dced41d6779f0f9cc279570c7645174f475`.
- [x] Create rollback ref `codex/before-android-identity-20261015` and working branch `codex/android-identity-isolation`.
- [x] Finish parallel Android and cloud-service audits.
- [x] Set `applicationId "com.kisin.cashew"` and `namespace 'com.kisin.cashew'`; change only the package declarations in the five Kotlin sources to `package com.kisin.cashew`. Keep their current physical directories and all component short names.
- [x] Inspect the diff and verify the `Cashew` manifest label remains unchanged.

## Task 2: Local verification and handoff

**Files:**
- Create: `docs/ANDROID_IDENTITY.md`, current findings and upgrade/migration requirements.
- Create: current chat `outputs/android-identity/` report and evidence; intermediate logs go in current chat `work/android-identity/`.

- [x] Run `scripts/flutter.ps1 test --no-pub`; inspect the exit status and full result.
- [x] Run `scripts/build-apk.ps1 -Optimized` with the existing environment and record the actual result. Do not bypass Google Services or alter credentials.
- [x] If the build succeeds, inspect the newly built APK using aapt2/apksigner/zipalign; require `com.kisin.cashew`, `Cashew`, expected components, package-scoped authorities, valid signature and alignment before export.
- [x] If the build is blocked by missing new Firebase/OAuth registration, stop that work and report that no validated new APK exists.
- [x] Inspect the existing test signing certificate locally without exporting its private key. Explain the current debug key, a durable release key decision before initial distribution, fixed package+certificate, increasing versionCode, and key backup requirements.
- [x] Document manual export/import migration into the new package's independent data sandbox; do not perform migration.
- [x] Request a read-only review, inspect the final diff, and save the report plus a reversible source patch.

## Outcome

The initial credential blocker was resolved when the user supplied a genuine matching Firebase config. The new Release APK built successfully and passed final-package identity, label, five component names, four authority prefixes, six Firebase resources, signature and alignment checks. Flutter tests passed 26/26. Android device/cloud-service runtime acceptance remains separate; no APK was installed.

## Task 3: Resume with user-supplied Firebase configuration

**Files:**
- Modify: `budget/android/app/google-services.json` from the exact user download.
- Modify: `budget/lib/firebase_options.dart`, Android options only.
- Modify: `scripts/build-apk.ps1`, generated-asset directory attribute normalization for the observed Windows build failure.

- [x] Inspect both real downloads; select `(1)` because it includes the matching Android certificate and Web OAuth client.
- [x] Back up original config/options/build script in chat work and preserve the prior source patch.
- [x] Copy the JSON byte-for-byte and synchronize the five Android FirebaseOptions fields; independently verify other platform options unchanged.
- [x] Run Flutter tests: 26/26 pass.
- [x] Observe the real generated-assets cleanup failure, inspect ReadOnly flags, add the narrowly scoped attribute fix, and obtain a successful complete build without skipping tasks or removing features.
- [x] Inspect the actual APK manifest, Firebase resources, signatures and alignment; require the existing signer and new package identity.
- [x] Export the APK, metadata, hashes, report, build evidence and reversible source patch to current chat outputs.
- [x] Verify protected originals, unchanged main/rollback refs and reverse-patch applicability; do not install, deploy or operate ledgers.
