// c 2025-07-27
// m 2025-08-18

class Folder : Entry {
    dictionary _entries;
    Entry@[]   entries;
    bool       enumerated   = false;
    bool       favorite     = false;
    bool       treeOpen     = false;
    bool       pluginFolder = false;
    string     pluginId;

    bool get_exists() override {
        return IO::FolderExists(path);
    }

    string get_icon() override {
        return treeOpen ? Icons::FolderOpen : Icons::Folder;
    }

    Folder(const string&in path) {
        super(path);
        type = Entry::Type::Folder;

        while (this.path.EndsWith("/")) {
            this.path = this.path.SubStr(0, this.path.Length - 1);
        }

        pluginId = Path::GetFileName(this.path);
    }

    void ClearEntries() {
        for (int i = entries.Length - 1; i >= 0; i--) {
            entries[i].valid = false;

            if (entries[i].type == Entry::Type::Folder) {
                cast<Folder>(entries[i]).ClearEntries();
            }

            entries.RemoveAt(i);
        }

        _entries.DeleteAll();
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
        if (!exists) {
            ClearEntries();
            return;
        }

        string[]@ index = IO::IndexFolder(path, false);
        string name;
        for (uint i = 0; i < index.Length; i++) {
            name = Path::GetFileName(
                index[i].EndsWith("/")
                ? index[i].SubStr(0, index[i].Length - 1)
                : index[i]
            );

            if (IO::FileExists(index[i])) {
                if (_entries.Exists(name)) {
                    auto file = cast<File>(_entries[name]);
                    if (file is null) {
                        @file = File(cast<Entry>(_entries[name]).path);
                        @file.parent = this;

                        _entries.Set(name, @file);

                        for (uint j = 0; j < entries.Length; j++) {
                            if (entries[j].name == name) {
                                @entries[j] = file;
                                break;
                            }
                        }
                    }

                } else {
                    auto file = File(index[i]);
                    @file.parent = this;
                    _entries.Set(name, @file);
                    entries.InsertLast(file);
                }

            } else {
                if (_entries.Exists(name)) {
                    auto folder = cast<Folder>(_entries[name]);
                    if (folder is null) {
                        @folder = Folder(cast<Entry>(_entries[name]).path);
                        @folder.parent = this;

                        _entries.Set(name, @folder);

                        for (uint j = 0; j < entries.Length; j++) {
                            if (entries[j].name == name) {
                                @entries[j] = folder;
                                break;
                            }
                        }
                    }

                } else {
                    auto folder = Folder(index[i]);
                    @folder.parent = this;
                    _entries.Set(name, @folder);
                    entries.InsertLast(folder);
                }
            }
        }

        for (int i = entries.Length - 1; i >= 0; i--) {
            if (index.Find(entries[i].path + (entries[i].type == Entry::Type::Folder ? "/" : "")) == -1) {
                entries[i].valid = false;
                if (_entries.Exists(entries[i].name)) {
                    _entries.Delete(entries[i].name);
                }
                entries.RemoveAt(i);
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
        if (_entries.Exists(name)) {
            return cast<File>(_entries[name]);
        }

        if (recursive) {
            for (uint i = 0; i < entries.Length; i++) {
                if (entries[i].type == Entry::Type::Folder) {
                    return cast<Folder>(entries[i]).GetFile(name, true);
                }
            }
        }

        return null;
    }

    Folder@ GetFolder(const string&in name, const bool recursive = false) {
        if (_entries.Exists(name)) {
            return cast<Folder>(_entries[name]);
        }

        if (recursive) {
            for (uint i = 0; i < entries.Length; i++) {
                if (entries[i].type == Entry::Type::Folder) {
                    return entries[i].name == name
                        ? cast<Folder>(entries[i])
                        : cast<Folder>(entries[i]).GetFolder(name, true)
                    ;
                }
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
        RenderContextMenu();
        if (treeOpen) {
            if (!enumerated) {
                Enumerate();
            }
        } else {
            enumerated = false;
            return;
        }

        const float indent = UI::GetScale() * 30.0f;

        if (this is workingFolder) {
            UI::Indent(indent);
            if (UI::Selectable("\\$FF8" + Icons::Folder + "\\$G ..", false)) {
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
                case Entry::Type::File:
                    UI::Indent(indent);
                    if (UI::Selectable("\\$88F" + entries[i].icon + "\\$G " + entries[i].name, false)) {
                        cast<File>(entries[i]).Edit();
                    }
                    if (UI::IsItemClicked(UI::MouseButton::Right)) {
                        entries[i].RightClick();
                    }
                    UI::Indent(-indent);

                    entries[i].RenderContextMenu();

                    break;

                case Entry::Type::Folder:
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

        entries.Sort(Entry::SortAsc);
    }

    void UnloadPlugin() {
        Meta::Plugin@ plugin = Meta::GetPluginFromID(pluginId);
        if (plugin !is null) {
            Meta::UnloadPlugin(plugin);
        }
    }
}
