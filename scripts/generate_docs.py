#!/usr/bin/env python3
import re
import os

def get_hypr_keys():
    keys = []
    config_path = "hypr/hyprland.conf"
    if not os.path.exists(config_path):
        return ""

    with open(config_path, "r") as f:
        content = f.read()
        # Ищем bind = MOD, KEY, exec, CMD
        matches = re.findall(r'bind\s*=\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*(.+)', content)
        for m in matches:
            mod, key, action, cmd = [x.strip() for x in m]
            if action == "exec":
                keys.append(f"| {mod} + {key} | {cmd} |")

    return "\n".join(keys)

def get_packages():
    pkg_vars = "ansible/roles/packages/vars/main.yml"
    if not os.path.exists(pkg_vars):
        return "Not found"

    pkgs = []
    with open(pkg_vars, "r") as f:
        for line in f:
            match = re.search(r'^\s*-\s*([a-zA-Z0-9\-_]+)', line)
            if match:
                pkgs.append(match.group(1))

    return ", ".join(pkgs[:15]) + "..."

def update_readme():
    readme_path = "README.md"
    if not os.path.exists(readme_path):
        return

    with open(readme_path, "r") as f:
        content = f.read()

    # Замена секции Hotkeys
    keys_table = "### ⌨️ Hotkeys\n| Key | Action |\n|-----|--------|\n" + get_hypr_keys()
    if "### ⌨️ Hotkeys" in content:
        content = re.sub(r'### ⌨️ Hotkeys.*?(?=\n\n##|\Z)', keys_table, content, flags=re.DOTALL)
    else:
        content += "\n\n" + keys_table

    # Замена секции Packages
    pkg_list = f"**Packages:** {get_packages()}"
    if "**Packages:**" in content:
        content = re.sub(r'\*\*Packages:\*\*.*', pkg_list, content)
    else:
        content += "\n\n" + pkg_list

    with open(readme_path, "w") as f:
        f.write(content)

if __name__ == "__main__":
    update_readme()
    print("Documentation updated in README.md")
