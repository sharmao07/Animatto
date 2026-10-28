// Prevents additional console window on Windows in release
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use tauri::{Manager, Window};
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct PlatformInfo {
    pub os: String,
    pub is_transparent_supported: bool,
    pub click_through_supported: bool,
    pub always_on_top_supported: bool,
    pub compositor_notes: String,
}

#[tauri::command]
fn get_platform_info() -> PlatformInfo {
    let os = std::env::consts::OS.to_string();
    let is_linux = os == "linux";
    
    let (is_transparent_supported, compositor_notes) = if is_linux {
        // Under Linux, check if Wayland or X11 is in use
        let session_type = std::env::var("XDG_SESSION_TYPE").unwrap_or_else(|_| "unknown".to_string());
        if session_type.to_lowercase().contains("wayland") {
            (
                false,
                "Wayland detected: Transparent desktop positioning and click-through require compositor layer-shell extensions."
                    .to_string(),
            )
        } else {
            (
                true,
                "X11 detected: Window transparency requires an active compositor (e.g. Picom/Compton)."
                    .to_string(),
            )
        }
    } else {
        (true, "Native window transparency and composition supported.".to_string())
    };

    PlatformInfo {
        os: os.clone(),
        is_transparent_supported,
        click_through_supported: os != "linux",
        always_on_top_supported: true,
        compositor_notes,
    }
}

#[tauri::command]
fn set_click_through(window: Window, ignore: bool) -> Result<(), String> {
    window
        .set_ignore_cursor_events(ignore)
        .map_err(|e| format!("Failed to set ignore_cursor_events: {}", e))
}

#[tauri::command]
fn set_companion_position(window: Window, x: f64, y: f64) -> Result<(), String> {
    window
        .set_position(tauri::Position::Physical(tauri::PhysicalPosition {
            x: x as i32,
            y: y as i32,
        }))
        .map_err(|e| format!("Failed to set window position: {}", e))
}

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            if let Some(window) = app.get_webview_window("companion") {
                // Ensure always on top and transparent initialization
                let _ = window.set_always_on_top(true);
            }
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            get_platform_info,
            set_click_through,
            set_companion_position
        ])
        .run(tauri::generate_context!())
        .expect("error while running animatto prototype tauri application");
}
