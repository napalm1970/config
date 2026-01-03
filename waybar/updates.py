#!/usr/bin/env python3
import subprocess
import json
import sys

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
    native = get_native_updates()
    aur = get_aur_updates()
    
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