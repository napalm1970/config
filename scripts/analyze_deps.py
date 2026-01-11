#!/usr/bin/env python3
import subprocess
import os

# Файлы
PKGLIST = "pkglist.txt"
REPORT_FILE = "dependency_report.md"

def get_dependencies(pkg_name):
    """Получает список прямых зависимостей пакета через pacman -Si (удаленная база)"""
    try:
        # Используем -Si, чтобы проверять даже неустановленные пакеты
        result = subprocess.run(['pacman', '-Si', pkg_name], capture_output=True, text=True)
        
        # Если пакет не найден в репозиториях (например, это AUR или имя неправильное)
        if result.returncode != 0:
            return ["(Не найден в официальных репо - возможно AUR)"]

        for line in result.stdout.splitlines():
            if line.strip().startswith("Depends On"):
                # Пример строки: "Depends On : glibc  gcc-libs  sh"
                deps_raw = line.split(":", 1)[1].strip()
                if deps_raw == "None":
                    return []
                # Очищаем от версий (например, "bash>=5.0" превращаем в "bash")
                deps = []
                for d in deps_raw.split():
                    # Отрезаем всё после >, <, =
                    clean_name = d.split('>')[0].split('<')[0].split('=')[0]
                    deps.append(clean_name)
                return deps
    except Exception as e:
        return [f"Ошибка: {e}"]
    return []

def main():
    if not os.path.exists(PKGLIST):
        print(f"Файл {PKGLIST} не найден!")
        return

    print("Анализ зависимостей (это может занять время)...")
    
    with open(PKGLIST, 'r') as f:
        packages = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    with open(REPORT_FILE, 'w') as f:
        f.write(f"# Отчет о зависимостях ({len(packages)} пакетов)\n\n")
        
        for pkg in sorted(packages):
            deps = get_dependencies(pkg)
            
            f.write(f"### 📦 {pkg}\n")
            if not deps:
                f.write("*Нет зависимостей*\n\n")
            elif deps[0].startswith("("):
                f.write(f"*{deps[0]}*\n\n")
            else:
                f.write("Зависит от:\n")
                for d in deps:
                    f.write(f"- {d}\n")
                f.write("\n")
                
    print(f"Готово! Отчет сохранен в {REPORT_FILE}")

if __name__ == "__main__":
    main()
