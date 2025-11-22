#!/usr/bin/env python3

from datetime import datetime
import json
import subprocess
from gi.repository import Gtk, GLib, Adw, Gdk
import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')


APP_ID = "org.example.hyprland-status-widget"


def get_keyboard_layout():
    """Fetches the current keyboard layout from Hyprland."""
    try:
        result = subprocess.run(
            ['hyprctl', '-j', 'devices'], capture_output=True, text=True, check=True)
        devices = json.loads(result.stdout)
        for device in devices.get('keyboards', []):
            if device.get('main', False):
                return device.get('active_keymap', 'N/A').upper()
        return 'N/A'
    except Exception:
        return 'ERR'


class MainWindow(Gtk.ApplicationWindow):
    def __init__(self, *args, **kwargs):
        super().__init__(
            *args,
            decorated=False,
            **kwargs
        )

        self.set_title("hyprland-status-widget")

        self.label = Gtk.Label(label="")
        self.label.set_css_classes(["widget-label"])
        self.set_child(self.label)

        # Обновляем текст каждую секунду
        self.update_text()
        GLib.timeout_add_seconds(1, self.update_text)

    def update_text(self):
        layout = get_keyboard_layout()
        current_time = datetime.now().strftime('%H:%M:%S')
        self.label.set_text(f"{layout} | {current_time}")
        return True  # Required for timeout_add to repeat


class MyApp(Adw.Application):
    def __init__(self, **kwargs):
        super().__init__(application_id=APP_ID, **kwargs)
        self.connect('activate', self.on_activate)

    def on_activate(self, app):
        self.win = MainWindow(application=app)
        self.win.present()
        GLib.timeout_add_seconds(5, self.quit_app)

    def quit_app(self):
        self.quit()


if __name__ == "__main__":
    # Добавляем стили для виджета
    css_provider = Gtk.CssProvider()
    css_provider.load_from_data("""
    .widget-label {
        font-size: 1.5em;
        font-weight: bold;
        color: white;
    }
    window {
        background-color: rgba(0, 0, 0, 0.6);
        border-radius: 8px;
        padding: 4px 12px;
    }
    """)
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        css_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

    app = MyApp()
    app.run(None)
