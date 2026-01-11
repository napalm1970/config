#!/usr/bin/env python3
import subprocess
import json
import sys
import os

def get_ignored_packages():
    """Reads IgnorePkg from /etc/pacman.conf"""
    ignored = set()
    try:
        with open("/etc/pacman.conf", "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("IgnorePkg"):
                    # Handle "IgnorePkg = pkg1 pkg2"
                    parts = line.split("=")
                    if len(parts) > 1:
                        pkgs = parts[1].strip().split()
                        ignored.update(pkgs)
    except FileNotFoundError:
        pass
    return ignored

def get_native_updates():
    try:
        # checkupdates is part of pacman-contrib and safer than checking sync db directly
        output = subprocess.check_output(["checkupdates"], stderr=subprocess.DEVNULL)
        return output.decode("utf-8").splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

def get_aur_updates():
    try:
        # Using yay for AUR updates as requested
        output = subprocess.check_output(["yay", "-Qum"], stderr=subprocess.DEVNULL)
        return output.decode("utf-8").splitlines()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return []

def main():
    ignored = get_ignored_packages()
    
    # Filter out ignored packages
    native_raw = get_native_updates()
    native = [line for line in native_raw if line.split()[0] not in ignored]
    
    aur_raw = get_aur_updates()
    aur = [line for line in aur_raw if line.split()[0] not in ignored]
    
    total_count = len(native) + len(aur)
    
    if total_count == 0:
        print(json.dumps({"text": "", "tooltip": "System is up to date"}))
        return

    tooltip = []
    if native:
        tooltip.append("<b>Native Updates:</b>")
        tooltip.extend(native)
    
    if aur:
        if native:
            tooltip.append("") # Separator
        tooltip.append("<b>AUR Updates:</b>")
        tooltip.extend(aur)
        
    # Determine class for CSS styling
    css_class = "updates"
    if total_count > 20:
        css_class = "updates-critical"
        
    output = {
        "text": f"📦 {total_count}",
        "tooltip": "\n".join(tooltip),
        "class": css_class
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()