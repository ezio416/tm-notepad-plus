// c 2025-07-28
// m 2025-07-28

enum EntryType {
    File,
    Folder,
    Unknown
}

class Entry {
    int2           contextMenuLocation;
    bool           contextMenuOpen = false;
    Folder@        parent;
    string         path;
    EntryType      type            = EntryType::Unknown;

    bool get_exists() {
        return false;  // override
    }

    string get_icon() {
        return "";  // override
    }

    string get_name() {
        return Path::GetFileName(path);
    }

    Entry(const string&in path) {
        this.path = path.Replace("\\", "/");
    }

    bool Move(const string&in path) {
        try {
            IO::Move(this.path, path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void Open() {
        ;  // override
    }

    bool Rename(const string&in name) {
        try {
            IO::Move(path, Path::GetDirectoryName(path) + name);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void RenderContextMenu() {
        if (!contextMenuOpen) {
            return;
        }

        const int flags = UI::WindowFlags::None
            | UI::WindowFlags::AlwaysAutoResize
            | UI::WindowFlags::NoMove
            | UI::WindowFlags::NoResize
            | UI::WindowFlags::NoTitleBar
        ;

        UI::SetNextWindowPos(contextMenuLocation.x, contextMenuLocation.y, UI::Cond::Always);
        if (UI::Begin(pluginTitle + "##context-" + path, flags)) {
            UI::PushFont(UI::Font::DefaultBold);
            switch (type) {
                case EntryType::File:
                    if (UI::Selectable("Open in Editor", false)) {
                        Open();
                        contextMenuOpen = false;
                    }
                    break;

                case EntryType::Folder:
                    if (UI::Selectable("Open as Workspace", false)) {
                        Open();
                        contextMenuOpen = false;
                    }
                    break;
            }
            UI::PopFont();

            UI::Separator();

            if (type == EntryType::Folder) {
                if (UI::Selectable("Enumerate", false)) {
                    cast<Folder>(this).Enumerate();
                    contextMenuOpen = false;
                }

                if (UI::Selectable("Enumerate (recursive)", false)) {
                    cast<Folder>(this).Enumerate(true);
                    contextMenuOpen = false;
                }

                UI::Separator();
            }

            if (UI::Selectable("Delete", false)) {
                print("click delete");
                contextMenuOpen = false;
            }

            if (UI::Selectable("Rename", false)) {
                print("click rename");
                contextMenuOpen = false;
            }

            UI::Separator();

            if (UI::Selectable("Properties", false)) {
                print("click properties");
                contextMenuOpen = false;
            }
        }
        UI::End();
    }

    void RightClick() {
        print("right clicked " + name);

        const vec2 mousePos = UI::GetMousePos();
        contextMenuLocation = int2(int(mousePos.x), int(mousePos.y));

        contextMenuOpen = true;
        @activeContextMenu = this;
    }
}
