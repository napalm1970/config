#!/usr/bin/env python3
import subprocess
import os

# Файлы
PKGLIST = "pkglist.txt"
OUTPUT_FILE = "packages.md"

def get_dependencies(pkg_name):
    """Получает список прямых зависимостей пакета через pacman -Si"""
    try:
        result = subprocess.run(['pacman', '-Si', pkg_name], capture_output=True, text=True)
        
        if result.returncode != 0:
            return None # AUR или ошибка

        for line in result.stdout.splitlines():
            if line.strip().startswith("Depends On"):
                deps_raw = line.split(":", 1)[1].strip()
                if deps_raw == "None":
                    return []
                deps = []
                for d in deps_raw.split():
                    clean_name = d.split('>')[0].split('<')[0].split('=')[0]
                    deps.append(clean_name)
                return deps
    except Exception:
        return None
    return []

def main():
    if not os.path.exists(PKGLIST):
        print(f"Файл {PKGLIST} не найден!")
        return

    print("Генерация графа зависимостей для Obsidian...")
    
    with open(PKGLIST, 'r') as f:
        packages = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    with open(OUTPUT_FILE, 'w') as f:
        f.write("# Package Dependencies Graph\n\n")
        f.write("Этот файл сгенерирован для просмотра связей в Obsidian.\n\n")
        
        for pkg in sorted(packages):
            deps = get_dependencies(pkg)
            
            f.write(f"## {pkg}\n") # Заголовок пакета
            
            if deps is None:
                f.write("*AUR Package or Not Found*\n")
            elif not deps:
                f.write("*No dependencies*\n")
            else:
                for d in deps:
                    # Создаем ссылку [[dependency]]
                    f.write(f"- [[{d}]]\n")
            
            f.write("\n---\n\n") # Разделитель
                
    print(f"Готово! Файл {OUTPUT_FILE} создан.")

if __name__ == "__main__":
    main()
