# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-10-10

### Added

- Browse file-type navigation with Left / Right.
- Browse product navigation with Shift + Left / Right.
- Arrow illumination reflecting available navigation and list boundaries.
- Shift + encoder click to append an FX preset to the current plug-in chain.
- Shift + encoder click to load an Instrument, One-shot, or Loop while retaining FX.
- Erase + encoder click in Plug-in mode to remove only the selected plug-in.
- Encoder rotation to select plug-in slots when parameter editing is closed.
- Brief on-controller feedback for modified load and remove actions.
- A single PowerShell patcher that applies all improvements to the supported
  original Maschine 3.7.1 x64 executable without installing earlier prototypes.
- Installation, compatibility checking, and restoration launchers.
- SHA-256 checks for the original executable, generated patch, installed file,
  and restoration backup.
- Backup reuse and detection of an already installed patch.
- Support for custom executable paths through the `-Target` parameter.
- English and Russian installation instructions.
- Documentation of native One-shot loading into Sampler: ordinary loading can
  retain FX, while Shift-loading explicitly retains FX across source types.
- Distribution of custom Lua handlers without bundling the Maschine executable
  or original Native Instruments scripts.

### Fixed

- Product navigation now advances the deferred browser cache timer so selections
  reach the browser.
- Restored native fast result scrolling with Shift + encoder rotation after an
  early prototype assigned that combination to product selection.
- Shift-loading a One-shot now replaces the source through Sampler-specific
  operations, preserving FX when replacing sources such as Bass Synth.
- Loop loading now prepares a Sampler before native loop insertion, preserving
  FX when replacing sources such as Bass Synth.
- Installation no longer rejects unrelated drivers or services merely because
  their process names contain "Maschine".
- Installation and restoration ignore exited Maschine processes that remain
  visible in the Windows process list.

## Future development

These items are planned follow-up work, not implemented changes or commitments
for a particular release. Completed items will move into the appropriate
Unreleased category when implemented.

### Installation and recovery

- **Recover an interrupted installation.** Add an explicit recovery mode that
  can restore a verified original backup when the current executable no longer
  matches the complete patch. Keep normal restoration strict and clearly
  distinguish recovery from overwriting an unknown installation.
- **Make executable replacement resilient.** Generate and verify a temporary
  file beside the executable, then replace the target using an appropriate
  Windows replacement operation. Preserve the original backup and provide a
  recovery path for failures during installation or restoration.

### Runtime reliability

- **Handle source-loading failures.** Validate the selected sample before
  changing the source or clearing zones, contain Lua errors, and show useful
  failure feedback on the controller. Investigate whether NI's APIs support
  rolling back source changes when a load fails; rollback is not currently
  guaranteed.
- **Identify pending presets by file path.** Capture and revalidate the selected
  preset's path rather than relying only on its result-list index, so a refreshed
  result list cannot redirect a pending action to another preset.

### Verification

- **Include reproducible tests in the repository.** Add patcher checks covering
  installation, repeated installation, restoration, unsupported executables,
  invalid backups, and failure recovery. Include Lua command tests for context
  changes, chain preservation, deletion, and plug-in slot navigation. Keep model
  tests distinct from controller and native-loader validation.
