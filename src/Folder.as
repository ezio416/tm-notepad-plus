// c 2025-07-27
// m 2025-07-28

class Folder : Entry {
    Entry@[] entries;

    bool get_exists() override {
        return IO::FolderExists(path);
    }

    Folder(const string&in path) {
        super(path);
        type = EntryType::Folder;

        while (this.path.EndsWith("/")) {
            this.path = this.path.SubStr(0, this.path.Length - 1);
        }
    }

    bool Create() {
        try {
            IO::CreateFolder(path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool Delete(const bool recursive = false) {
        try {
            IO::DeleteFolder(path, recursive);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void Enumerate(const bool recursive = false, const bool ignoreGitFolder = true) {
        entries = {};

        if (exists) {
            string[]@ index = IO::IndexFolder(path, false);
            for (uint i = 0; i < index.Length; i++) {
                if (IO::FileExists(index[i])) {
                    auto file = File(index[i]);
                    print("found file: " + file.path);
                    @file.parent = this;
                    entries.InsertLast(file);
                } else {
                    auto folder = Folder(index[i]);
                    print("found folder: " + folder.path);

                    if (true
                        and ignoreGitFolder
                        and folder.name == ".git"
                    ) {
                        continue;
                    }

                    if (recursive) {
                        folder.Enumerate(true);
                    }

                    @folder.parent = this;
                    entries.InsertLast(folder);
                }
            }
        }
    }

    File@ GetFile(const string&in name) {
        for (uint i = 0; i < entries.Length; i++) {
            if (true
                and entries[i].type == EntryType::File
                and entries[i].name == name
            ) {
                return cast<File>(entries[i]);
            }
        }

        return null;
    }

    Folder@ GetFolder(const string&in name) {
        for (uint i = 0; i < entries.Length; i++) {
            if (true
                and entries[i].type == EntryType::Folder
                and entries[i].name == name
            ) {
                return cast<Folder>(entries[i]);
            }
        }

        return null;
    }

    void RenderTreeSimple() {
        if (!UI::TreeNode("\\$FF8" + Icons::Folder + "\\$G " + name)) {
            return;
        }

        for (uint i = 0; i < entries.Length; i++) {
            switch (entries[i].type) {
                case EntryType::File:
                    if (UI::Selectable("\\$88F" + Icons::File + "\\$G " + entries[i].name, false)) {
                        cast<File>(entries[i]).Edit();
                    }
                    break;

                case EntryType::Folder:
                    cast<Folder>(entries[i]).RenderTreeSimple();
                    break;
            }
        }

        UI::TreePop();
    }
}
