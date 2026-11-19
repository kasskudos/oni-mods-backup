"""Create a complete, byte-preserving Git snapshot of the ONI mods folder."""

import hashlib
import json
import os
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "_ptbr_master" / "backup-manifest.json"


def git(*args, data=None):
    result = subprocess.run(
        ["git", "-C", str(ROOT), *args], input=data,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True,
    )
    return result.stdout


def files():
    result = []
    for directory, names, filenames in os.walk(ROOT):
        names[:] = sorted(name for name in names if name != ".git")
        for name in sorted(filenames):
            path = Path(directory) / name
            if name != ".git":
                result.append(path)
    return sorted(result, key=lambda path: path.relative_to(ROOT).as_posix())


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def main():
    if (ROOT / ".git").exists():
        raise RuntimeError("Repository already exists; inspect before retrying.")
    readme = ROOT / "BACKUP.md"
    if readme.exists():
        raise RuntimeError("BACKUP.md already exists; refusing to overwrite.")
    readme.write_text(
        "# Backup dos mods de Oxygen Not Included\n\n"
        "Snapshot dos mods instalados, configurações, traduções, fontes, "
        "customizações, ferramentas e backups locais.\n\n"
        "Steam/ contém os mods do Workshop instalados. Local/ contém os mods "
        "locais. config/, settings/ e mods.json preservam configurações e "
        "ativação. _ptbr_master/ preserva traduções, fontes das correções, "
        "scripts, referências e backups das DLLs.\n\n"
        "Para restaurar, feche o jogo, preserve uma cópia da pasta atual e "
        "copie o conteúdo deste repositório para Documents/Klei/"
        "OxygenNotIncluded/mods. Os saves e o executável do jogo ficam fora "
        "deste backup. Atualizações da Steam podem substituir os mods "
        "restaurados.\n\n"
        "O manifesto _ptbr_master/backup-manifest.json registra tamanho e "
        "SHA256 dos arquivos do snapshot inicial, exceto o próprio manifesto. "
        "Metadados .git de repositórios de terceiros não são incluídos; "
        "seus arquivos de trabalho são preservados integralmente. Não há "
        "dependência de submódulos para restaurar o snapshot.\n\n"
        "Os mods de terceiros pertencem aos respectivos autores e mantêm "
        "suas licenças originais.\n",
        encoding="utf-8",
    )
    records = [
        {"path": path.relative_to(ROOT).as_posix(),
         "bytes": path.stat().st_size, "sha256": digest(path)}
        for path in files() if path != MANIFEST
    ]
    MANIFEST.write_text(json.dumps({"files": records}, ensure_ascii=False, indent=2)
                        + "\n", encoding="utf-8")
    git("init", "-b", "main")
    git("config", "core.autocrlf", "false")
    git("config", "core.longpaths", "true")
    (ROOT / ".git" / "info" / "attributes").write_text("* -text\n", encoding="utf-8")
    paths = files()
    # Build the index explicitly, including files ignored by vendor .gitignore
    # files and source trees that otherwise become embedded Git repositories.
    path_input = "".join(json.dumps(path.relative_to(ROOT).as_posix(),
                                   ensure_ascii=False) + "\n" for path in paths)
    hashes = git("hash-object", "-w", "--no-filters", "--stdin-paths",
                 data=path_input.encode("utf-8")).decode("ascii").splitlines()
    if len(hashes) != len(paths):
        raise RuntimeError("Unexpected blob count.")
    entries = b"".join(
        b"100644 " + value.encode("ascii") + b"\t"
        + path.relative_to(ROOT).as_posix().encode("utf-8") + b"\0"
        for path, value in zip(paths, hashes)
    )
    git("update-index", "-z", "--index-info", data=entries)
    for record in records:
        if digest(ROOT / record["path"]) != record["sha256"]:
            raise RuntimeError("File changed during backup: " + record["path"])
    git("commit", "-m", "Back up installed ONI mods and local customizations")
    tracked = git("ls-tree", "-r", "-z", "HEAD").split(b"\0")
    tracked = [entry for entry in tracked if entry]
    if len(tracked) != len(paths) or any(entry.startswith(b"160000") for entry in tracked):
        raise RuntimeError("Incomplete tree or unexpected submodule.")
    git("fsck", "--full")
    print(json.dumps({"root": str(ROOT), "files": len(paths),
                      "bytes": sum(path.stat().st_size for path in paths),
                      "commit": git("rev-parse", "HEAD").decode().strip()}, indent=2))


if __name__ == "__main__":
    main()
