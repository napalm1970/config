#!/usr/bin/env python3

import sys
import os
import json
import subprocess
import glob
from datetime import datetime
import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, GLib, Adw, Gdk

APP_ID = "org.napalm.hyprland-status"
CSS_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "style.css")
UPDATES_FILE = "/tmp/pending_updates"

def get_battery_info():
    try:
        battery_dir = glob.glob('/sys/class/power_supply/BAT*')[0]
        with open(os.path.join(battery_dir, 'capacity'), 'r') as f:
            capacity = int(f.read().strip())
        with open(os.path.join(battery_dir, 'status'), 'r') as f:
            status = f.read().strip()
        
        icon = ''
        if status == 'Charging':
            icon = ''
        elif status == 'Discharging':
            if capacity > 75: icon = ''
            elif capacity > 50: icon = ''
            elif capacity > 25: icon = ''
            else: icon = ''
        return icon, f"{capacity}%"
    except (IndexError, FileNotFoundError):
        return "", "N/A"

def get_keyboard_layout():
    try:
        result = subprocess.run(['hyprctl', '-j', 'devices'], capture_output=True, text=True)
        devices = json.loads(result.stdout)
        for device in devices.get('keyboards', []):
            if device.get('main', False):
                return device.get('active_keymap', 'EN').upper()[:2]
        return 'EN'
    except Exception:
        return 'ERR'

def get_updates_count():
    try:
        if os.path.exists(UPDATES_FILE):
            with open(UPDATES_FILE, 'r') as f:
                count = f.read().strip()
                return count if int(count) > 0 else None
    except Exception:
        pass
    return None

class StatusItem(Gtk.Box):
    def __init__(self, icon_class, icon_char):
        super().__init__(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        self.set_css_classes(["item-box"])
        
        self.icon_label = Gtk.Label(label=icon_char)
        self.icon_label.set_css_classes(["icon", icon_class])
        
        self.text_label = Gtk.Label(label="...")
        self.text_label.set_css_classes(["label"])
        
        self.append(self.icon_label)
        self.append(self.text_label)

    def set_text(self, text):
        self.text_label.set_text(text)
    
    def set_icon(self, icon):
        self.icon_label.set_text(icon)

class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, decorated=False, **kwargs)
        self.set_title("hyprland-status-widget")

        # Main Container
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        box.set_css_classes(["main-box"])
        self.set_child(box)

        # Widgets
        self.kbd_item = StatusItem("layout-icon", "")
        self.bat_item = StatusItem("battery-icon", "")
        self.time_item = StatusItem("time-icon", "")
        self.update_item = StatusItem("update-icon", "📦")
        
        box.append(self.kbd_item)
        box.append(self.bat_item)
        box.append(self.time_item)
        # Update item is appended only if updates exist (handled in update_ui)

        self.box = box
        self.update_ui()
        GLib.timeout_add(1000, self.update_ui)

    def update_ui(self):
        # Time
        current_time = datetime.now().strftime('%H:%M')
        self.time_item.set_text(current_time)

        # Keyboard
        self.kbd_item.set_text(get_keyboard_layout())

        # Battery
        icon, percent = get_battery_info()
        self.bat_item.set_icon(icon)
        self.bat_item.set_text(percent)

        # Updates
        updates = get_updates_count()
        if updates:
            self.update_item.set_text(updates)
            if self.update_item.get_parent() is None:
                self.box.append(self.update_item)
        else:
            if self.update_item.get_parent() is not None:
                self.box.remove(self.update_item)
        
        return True

class MyApp(Adw.Application):
    def __init__(self, **kwargs):
        super().__init__(application_id=APP_ID, **kwargs)
        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        self.win = MainWindow(application=app)
        self.win.present()
        # Close automatically after 4 seconds
        GLib.timeout_add_seconds(4, self.quit_app)

    def quit_app(self):
        self.quit()

if __name__ == "__main__":
    css_provider = Gtk.CssProvider()
    if os.path.exists(CSS_FILE):
        css_provider.load_from_path(CSS_FILE)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )
    
    app = MyApp()
    app.run(None)