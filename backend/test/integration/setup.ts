import { assertEmulatorOnly } from './emulator-guard.js';

// Runs before any integration test file is imported: abort unless on the local emulators.
assertEmulatorOnly();
