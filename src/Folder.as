// c 2025-07-27
// m 2025-07-30

class Folder : Entry {
    Entry@[] entries;
    bool     enumerated   = false;
    bool     treeOpen     = false;
    bool     pluginFolder = false;
    string   pluginId;

    bool get_exists() override {
        return IO::FolderExists(path);
    }

    string get_icon() override {
        return treeOpen ? Icons::FolderOpen : Icons::Folder;
    }

    Folder(const string&in path) {
        super(path);
        type = EntryType::Folder;

        while (this.path.EndsWith("/")) {
            this.path = this.path.SubStr(0, this.path.Length - 1);
        }

        pluginId = Path::GetFileName(this.path);
    }

    bool Create() override {
        if (exists) {
            return true;
        }

        try {
            IO::CreateFolder(path);
            trace("created folder: " + path);
            return true;
        } catch {
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool CreateFile(const string&in name = "") {
        if (name.Length == 0) {
            string newFileName = "New Text Document";
            if (IO::FileExists(path + "/" + newFileName + ".txt")) {
                uint i = 2;
                newFileName += " (" + i + ")";
                while (IO::FileExists(path + "/" + newFileName + ".txt")) {
                    newFileName = newFileName.Replace("(" + i + ")", "(" + (i + 1) + ")");
                    i++;
                }
            }

            return File(path + "/" + newFileName + ".txt").Create();
        }

        return File(path + "/" + name).Create();
    }

    bool CreateFolder(const string&in name = "") {
        if (name.Length == 0) {
            string newFolderName = "New folder";
            if (IO::FolderExists(path + "/" + newFolderName)) {
                uint i = 2;
                newFolderName += " (" + i + ")";
                while (IO::FolderExists(path + "/" + newFolderName)) {
                    newFolderName = newFolderName.Replace("(" + i + ")", "(" + (i + 1) + ")");
                    i++;
                }
            }

            return Folder(path + "/" + newFolderName).Create();
        }

        return Folder(path + "/" + name).Create();
    }

    bool Delete(const bool recursive = false) {
        try {
            IO::DeleteFolder(path, recursive);
            warn("deleted folder and its contents: " + path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void Enumerate() {
        entries = {};

        if (exists) {
            string[]@ index = IO::IndexFolder(path, false);
            for (uint i = 0; i < index.Length; i++) {
                if (IO::FileExists(index[i])) {
                    auto file = File(index[i]);
                    // trace("found file: " + file.path);
                    @file.parent = this;
                    entries.InsertLast(file);

                } else {
                    auto folder = Folder(index[i]);
                    // trace("found folder: " + folder.path);
                    @folder.parent = this;
                    entries.InsertLast(folder);
                }
            }
        }

        SortEntries();

        pluginFolder = false;

        if (Path::GetDirectoryName(path).EndsWith("/Plugins/")) {
            Meta::Plugin@ plugin = Meta::GetPluginFromID(pluginId);
            if (plugin !is null) {
                pluginFolder = true;
            } else {
                Meta::UnloadedPluginInfo[]@ unloaded = Meta::UnloadedPlugins();
                for (uint i = 0; i < unloaded.Length; i++) {
                    if (unloaded[i].ID == pluginId) {
                        pluginFolder = true;
                        break;
                    }
                }
            }
        }

        enumerated = true;
    }

    File@ GetFile(const string&in name, const bool recursive = false) {
        for (uint i = 0; i < entries.Length; i++) {
            switch (entries[i].type) {
                case EntryType::File:
                    if (entries[i].name == name) {
                        return cast<File>(entries[i]);
                    }
                    break;

                case EntryType::Folder:
                    if (recursive) {
                        return cast<Folder>(entries[i]).GetFile(name, true);
                    }
                    break;
            }
        }

        return null;
    }

    Folder@ GetFolder(const string&in name, const bool recursive = false) {
        for (uint i = 0; i < entries.Length; i++) {
            switch (entries[i].type) {
                case EntryType::Folder:
                    if (entries[i].name == name) {
                        return cast<Folder>(entries[i]);
                    }

                    if (recursive) {
                        return cast<Folder>(entries[i]).GetFolder(name, true);
                    }

                    break;
            }
        }

        return null;
    }

    bool LoadPlugin() {
        try {
            Meta::Plugin@ plugin = Meta::LoadPlugin(
                path + "/",
                Meta::PluginSource::UserFolder,
                Meta::PluginType::Folder
            );
            return plugin !is null;
        } catch {
            return false;
        }
    }

    void Open() override {
        SetWorkingFolder(this);
    }

    void ReloadPlugin() {
        Meta::Plugin@ plugin = Meta::GetPluginFromID(pluginId);
        if (plugin !is null) {
            Meta::ReloadPlugin(plugin);
        }
    }

    void RenderTreeSimple() {
        int flags = UI::TreeNodeFlags::None;
        if (this is workingFolder) {
            flags |= UI::TreeNodeFlags::DefaultOpen;
        }

        treeOpen = UI::TreeNode("\\$FF8" + icon + "\\$G " + name + "###" + path, flags);
        if (UI::IsItemClicked(UI::MouseButton::Right)) {
            RightClick();
        }
        if (treeOpen) {
            if (!enumerated) {
                Enumerate();
            }
        } else {
            enumerated = false;
            return;
        }

        if (this is workingFolder) {
            const float indent = UI::GetScale() * 30.0f;
            UI::Indent(indent);
            if (UI::Selectable("\\$FF8" + icon + "\\$G ..", false)) {
                if (parent is null) {
                    @parent = Folder(Path::GetDirectoryName(path));
                }
                if (parent.path.Length > 0) {
                    trace("going up to " + parent.path);
                    SetWorkingFolder(parent);
                } else {
                    warn("you're already at the top!");
                }
            }
            UI::SetItemTooltip("Go up a folder");
            UI::Indent(-indent);
        }

        for (uint i = 0; i < entries.Length; i++) {
            switch (entries[i].type) {
                case EntryType::File:
                    if (UI::Selectable("\\$88F" + entries[i].icon + "\\$G " + entries[i].name, false)) {
                        cast<File>(entries[i]).Edit();
                    }
                    if (UI::IsItemClicked(UI::MouseButton::Right)) {
                        entries[i].RightClick();
                    }
                    break;

                case EntryType::Folder:
                    cast<Folder>(entries[i]).RenderTreeSimple();
                    break;
            }
        }

        UI::TreePop();
    }

    void SortEntries() {
        if (entries.Length < 2) {
            return;
        }

        Entry@[] sorted;

        for (uint i = 0; i < entries.Length; i++) {
            if (entries[i].type == EntryType::Folder) {
                sorted.InsertLast(entries[i]);
            }
        }

        for (uint i = 0; i < entries.Length; i++) {
            if (entries[i].type == EntryType::File) {
                sorted.InsertLast(entries[i]);
            }
        }

        entries = sorted;
    }

    void UnloadPlugin() {
        Meta::Plugin@ plugin = Meta::GetPluginFromID(pluginId);
        if (plugin !is null) {
            Meta::UnloadPlugin(plugin);
        }
    }
}
