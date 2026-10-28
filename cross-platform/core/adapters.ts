/**
 * Animatto Platform Adapter Interfaces
 * Clean abstractions separating platform-specific OS calls from the portable behavior core.
 */

export interface ScreenBounds {
  x: number;
  y: number;
  width: number;
  height: number;
  scaleFactor: number;
}

export interface PlatformWindowAdapter {
  readonly platformName: 'macos' | 'windows' | 'linux';
  
  /** Sets window click-through (ignoring mouse events to let user click through the transparent desktop surface) */
  setClickThrough(enabled: boolean): Promise<boolean>;
  
  /** Keeps companion always on top of other windows */
  setAlwaysOnTop(enabled: boolean): Promise<boolean>;
  
  /** Moves companion window in physical screen coordinates */
  setPosition(x: number, y: number): Promise<void>;
  
  /** Queries active monitor/display bounds */
  getPrimaryDisplayBounds(): Promise<ScreenBounds>;
  
  /** Detects whether transparency is supported in the current compositor (critical for Linux Wayland) */
  supportsTransparency(): boolean;
}

export interface PlatformEnvironmentAdapter {
  /** Queries global cursor position */
  getCursorPosition(): Promise<{ x: number; y: number } | null>;
  
  /** Queries currently active focused application identifier or title */
  getActiveAppInfo(): Promise<{ name?: string; bundleOrClass?: string } | null>;
  
  /** Queries elapsed seconds since last user keyboard or mouse input */
  getSystemIdleSeconds(): Promise<number>;
}

export interface PlatformStorageAdapter {
  /** Returns standard application data root directory for this OS */
  getApplicationDataDir(): string;
  
  /** Returns local companion assets storage directory */
  getCompanionsDir(): string;
  
  /** Reads text file from application storage */
  readTextFile(path: string): Promise<string>;
  
  /** Atomically writes text file to application storage */
  writeTextFile(path: string, contents: string): Promise<void>;
}

export interface PlatformNotificationAdapter {
  /** Emits a native system desktop notification */
  showNotification(title: string, body: string): Promise<boolean>;
}

/**
 * Explicit stub implementation for unsupported platforms or experimental environments.
 * Prevents silent failures by explicitly rejecting or logging unsupported operations.
 */
export class UnsupportedPlatformAdapter implements PlatformWindowAdapter, PlatformEnvironmentAdapter {
  public readonly platformName: 'macos' | 'windows' | 'linux';

  constructor(platformName: 'macos' | 'windows' | 'linux') {
    this.platformName = platformName;
  }

  public async setClickThrough(_enabled: boolean): Promise<boolean> {
    console.warn(`[Animatto Adapter] setClickThrough not supported on ${this.platformName} without native extensions.`);
    return false;
  }

  public async setAlwaysOnTop(_enabled: boolean): Promise<boolean> {
    console.warn(`[Animatto Adapter] setAlwaysOnTop not supported on ${this.platformName}.`);
    return false;
  }

  public async setPosition(_x: number, _y: number): Promise<void> {
    // No-op
  }

  public async getPrimaryDisplayBounds(): Promise<ScreenBounds> {
    return { x: 0, y: 0, width: 1920, height: 1080, scaleFactor: 1.0 };
  }

  public supportsTransparency(): boolean {
    // Linux Wayland compositors often restrict transparent window positioning without layer-shell
    return this.platformName !== 'linux';
  }

  public async getCursorPosition(): Promise<{ x: number; y: number } | null> {
    return null;
  }

  public async getActiveAppInfo(): Promise<{ name?: string; bundleOrClass?: string } | null> {
    return null;
  }

  public async getSystemIdleSeconds(): Promise<number> {
    return 0;
  }
}
