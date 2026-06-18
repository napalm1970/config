"""
Интеграционные тесты состояния конфигов репозитория.
Запуск: python3 scripts/test_dotfiles.py [-v]
"""
import os
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


class TestGeminiRemoved(unittest.TestCase):
    """Убеждаемся, что gemini-интеграция полностью удалена."""

    ALLOWED = {"fish-ai.ini"}  # оставлен намеренно

    def _tracked_files_with_gemini(self):
        result = subprocess.run(
            ["git", "grep", "-il", "gemini"],
            cwd=ROOT,
            capture_output=True,
            text=True,
        )
        return {
            p for p in result.stdout.splitlines() if Path(p).name not in self.ALLOWED
        }

    def test_no_gemini_references(self):
        matches = self._tracked_files_with_gemini()
        self.assertFalse(
            matches,
            f"Упоминания gemini остались в: {sorted(matches)}",
        )

    def test_no_gemini_functions(self):
        for name in ("gemini_context.fish", "load_gemini_key.fish",
                     "voice_gemini.fish", "voice_gemini_init.fish"):
            self.assertFalse(
                (ROOT / "fish/functions" / name).exists(),
                f"Файл не удалён: fish/functions/{name}",
            )

    def test_no_gemini_nvim_plugins(self):
        for name in ("gemini-companion.lua", "gemini-cli.lua.disabled"):
            self.assertFalse(
                (ROOT / "nvim/lua/plugins" / name).exists(),
                f"Файл не удалён: nvim/lua/plugins/{name}",
            )

    def test_no_gitmodules(self):
        self.assertFalse(
            (ROOT / ".gitmodules").exists(),
            ".gitmodules не удалён (submodule gemini-cli-prompt-library)",
        )


class TestRequiredFiles(unittest.TestCase):
    """Файлы, критичные для работы рабочего стола после переустановки."""

    REQUIRED = [
        "hypr/scripts/autoname.py",
        "waybar/gammastep_status.sh",
        "waybar/gammastep-config.ini",
        "hypr/pyprland.toml",
        "fish/config.fish",
        "CLAUDE.md",
    ]

    def test_files_exist(self):
        missing = [p for p in self.REQUIRED if not (ROOT / p).exists()]
        self.assertFalse(missing, f"Отсутствуют файлы: {missing}")

    def test_pyprland_toml_is_regular_file(self):
        """Должен быть обычным файлом, а не симлинком на ~/.config/pypr."""
        path = ROOT / "hypr/pyprland.toml"
        self.assertFalse(
            path.is_symlink(),
            "hypr/pyprland.toml — симлинк; на чистой системе сломается",
        )

    def test_autoname_py_is_executable(self):
        path = ROOT / "hypr/scripts/autoname.py"
        self.assertTrue(os.access(path, os.X_OK), "autoname.py не исполняемый")


class TestAnsiblePackages(unittest.TestCase):
    """Проверяем список пакетов Ansible для чистой установки."""

    def _load_packages(self):
        import yaml

        with open(ROOT / "ansible/group_vars/all/main.yml") as f:
            return yaml.safe_load(f)

    def test_awww_present(self):
        data = self._load_packages()
        self.assertIn("awww", data.get("aur_packages", []),
                      "awww не в aur_packages (обои не запустятся)")

    def test_swww_removed(self):
        data = self._load_packages()
        self.assertNotIn("swww", data.get("aur_packages", []),
                         "swww в aur_packages — конфиг использует awww")

    def test_pyprland_present(self):
        data = self._load_packages()
        self.assertIn("pyprland", data.get("aur_packages", []),
                      "pyprland не в aur_packages (скретчпады не запустятся)")

    def test_qalculate_present(self):
        data = self._load_packages()
        self.assertIn("qalculate-gtk", data.get("system_packages", []),
                      "qalculate-gtk не в system_packages (скретчпад calc сломан)")


class TestFishSyntax(unittest.TestCase):
    """Синтаксис всех fish-файлов."""

    def _check(self, path):
        result = subprocess.run(
            ["fish", "-n", str(path)],
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode, 0,
            f"fish -n {path.relative_to(ROOT)} сообщил:\n{result.stderr}",
        )

    def test_config_fish(self):
        self._check(ROOT / "fish/config.fish")

    def test_functions(self):
        for path in sorted((ROOT / "fish/functions").glob("*.fish")):
            with self.subTest(file=path.name):
                self._check(path)


class TestPythonSyntax(unittest.TestCase):
    """py_compile для всех Python-скриптов."""

    SCRIPTS = [
        "scripts/generate_docs.py",
        "scripts/check_weather.py",
        "scripts/check_mail.py",
        "scripts/swedbank_pension.py",
        "scripts/punto.py",
        "hypr/scripts/autoname.py",
        "hyprland-status/main.py",
    ]

    def test_compile(self):
        for rel in self.SCRIPTS:
            with self.subTest(file=rel):
                result = subprocess.run(
                    ["python3", "-m", "py_compile", str(ROOT / rel)],
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.returncode, 0,
                    f"py_compile {rel}:\n{result.stderr}",
                )


class TestGenerateDocs(unittest.TestCase):
    """generate_docs.py должен быть идемпотентным."""

    def _run_generator(self):
        subprocess.run(
            ["python3", "scripts/generate_docs.py"],
            cwd=ROOT,
            capture_output=True,
        )

    def _readme_content(self):
        return (ROOT / "README.md").read_text()

    def test_idempotent(self):
        self._run_generator()
        after_first = self._readme_content()
        self._run_generator()
        after_second = self._readme_content()
        self.assertEqual(after_first, after_second,
                         "generate_docs.py не идемпотентен: README меняется при повторном запуске")

    def test_readme_ends_with_newline(self):
        self._run_generator()
        content = (ROOT / "README.md").read_bytes()
        self.assertTrue(content.endswith(b"\n"),
                        "README.md не заканчивается переводом строки после generate_docs.py")

    def test_hotkeys_section_present(self):
        self._run_generator()
        content = self._readme_content()
        self.assertIn("### ⌨️ Hotkeys", content)
        self.assertNotIn("$mainMod + G", content,
                         "Хоткей Gemini не удалён из README")

    def test_packages_section_present(self):
        self._run_generator()
        content = self._readme_content()
        self.assertIn("**Packages:**", content)


class TestAnsibleSyntax(unittest.TestCase):
    """ansible-playbook --syntax-check."""

    def test_syntax_check(self):
        result = subprocess.run(
            ["ansible-playbook", "playbooks/main.yml", "--syntax-check"],
            cwd=ROOT / "ansible",
            capture_output=True,
            text=True,
        )
        self.assertEqual(
            result.returncode, 0,
            f"ansible syntax-check:\n{result.stdout}\n{result.stderr}",
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
