// c 2025-07-28
// m 2025-08-19

namespace Entry {
    enum Type {
        File,
        Folder,
        Unknown
    }

    bool SortAsc(const Entry@const&in a, const Entry@const&in b) {
        if (a.type != b.type) {
            return a.type == Type::Folder;
        }

        return a.name.ToLower() < b.name.ToLower();
    }
}

class Entry {
    string      newName;
    Folder@     parent;
    string      path;
    bool        renameOpen = false;
    Entry::Type type       = Entry::Type::Unknown;
    bool        valid      = true;

    bool get_exists() {  // override
        return false;
    }

    string get_icon() {  // override
        return "";
    }

    string get_name() const final {
        return Path::GetFileName(path);
    }

    Entry(const string&in path) {
        this.path = path.Replace("\\", "/");
    }

    bool Create() {  // override
        return false;
    }

    bool Move(const string&in path) final {
        try {
            IO::Move(this.path, path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void Open() {  // override
    }

    void OpenContextMenu() final {
        UI::OpenPopup(pluginTitle + "##context-" + path);
    }

    bool Rename(const string&in name) final {
        try {
            IO::Move(path, Path::GetDirectoryName(path) + name);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void RenderContextMenu() final {
        if (!UI::BeginPopup(pluginTitle + "##context-" + path)) {
            return;
        }

        UI::PushFont(UI::Font::DefaultBold);
        switch (type) {
            case Entry::Type::File:
                if (UI::MenuItem(Icons::ExternalLinkSquare + " Open in Editor")) {
                    Open();
                }

                if (UI::MenuItem(Icons::ExternalLinkSquare + " Open in Editor (Text)")) {
                    cast<File>(this).Edit(true);
                }

                break;

            case Entry::Type::Folder:
                UI::BeginDisabled(this is workingFolder);
                if (UI::MenuItem(Icons::ExternalLinkSquare + " Open as Workspace")) {
                    Open();
                }
                UI::EndDisabled();

                if (UI::MenuItem(Icons::ExternalLink + " Open in Windows Explorer")) {
                    OpenExplorerPath(path);
                }

                if (
                    UI::MenuItem(Icons::ExternalLink + " Open in Preferred Text Editor ("
                    + tostring(Meta::GetPreferredTextEditor()) + ")")
                ) {
                    Meta::OpenTextEditor(path);
                }

                break;
        }
        UI::PopFont();

        if (type == Entry::Type::Folder) {
            UI::Separator();

            if (UI::BeginMenu(Icons::Plus + " New")) {
                if (UI::MenuItem(Icons::File + " File")) {
                    trace("creating new file in " + path);
                    auto folder = cast<Folder>(this);
                    if (folder.CreateFile()) {
                        folder.Enumerate();
                    }
                }

                if (UI::MenuItem(Icons::Folder + " Folder")) {
                    trace("creating new folder in " + path);
                    auto folder = cast<Folder>(this);
                    if (folder.CreateFolder()) {
                        folder.Enumerate();
                    }
                }

                UI::EndMenu();
            }
        }

        UI::Separator();

        if (UI::BeginMenu(Icons::Trash + " Delete")) {
            UI::AlignTextToFramePadding();
            UI::Text("Are you sure? This is permanent!");

            UI::SameLine();
            if (UI::ButtonColored(Icons::ExclamationTriangle + " YES " + Icons::ExclamationTriangle, 0.15f)) {
                switch (type) {
                    case Entry::Type::File:
                        if (true
                            and cast<File>(this).Delete()
                            and parent !is null
                        ) {
                            parent.Enumerate();
                        }
                        break;

                    case Entry::Type::Folder:
                        if (true
                            and cast<Folder>(this).Delete(true)
                            and parent !is null
                        ) {
                            parent.Enumerate();
                        }
                        break;
                }

                UI::CloseCurrentPopup();
            }

            UI::EndMenu();
        }

        if (UI::BeginMenu(Icons::Pencil + " Rename")) {
            if (!renameOpen) {
                newName = name;
                renameOpen = true;
            }

            bool enter = false;
            newName = UI::InputText("##New name", newName, enter, UI::InputTextFlags::EnterReturnsTrue);

            UI::SameLine();
            UI::BeginDisabled(false
                or newName.Length == 0
                or newName == name
            );
            if (true
                and (false
                    or enter
                    or UI::Button("Rename##button")
                )
                and Rename(newName)
            ) {
                newName = "";
                if (parent !is null) {
                    parent.Enumerate();
                }
                UI::CloseCurrentPopup();
            }
            UI::EndDisabled();

            UI::EndMenu();
        } else {
            renameOpen = false;
        }

        UI::Separator();

        if (UI::MenuItem(Icons::Info + " Properties")) {
            @activeProperties = this;
        }

        UI::EndPopup();
    }

    void RenderProperties() final {
        bool open;
        if (UI::Begin(pluginTitle + " Properties", open, UI::WindowFlags::AlwaysAutoResize)) {
            UI::Text(tostring(type) + ": " + name);
            UI::Text("Path: " + path);
            UI::Text("Exists: " + (type == Entry::Type::File ? IO::FileExists(path) : IO::FolderExists(path)));
            UI::Text("Created: " + Time::FormatString("%F %T", IO::FileCreatedTime(path)));
            UI::Text("Modified: " + Time::FormatString("%F %T", IO::FileModifiedTime(path)));
            if (type == Entry::Type::File) {
                const uint64 size = IO::FileSize(path);
                UI::Text("Size: " + FormatBytes(size) + (size > KiB ? " (" + size + " bytes)" : ""));
                UI::Text("Type: " + tostring(cast<File>(this).fileType));
            }
        }
        UI::End();

        if (!open) {
            @activeProperties = null;
        }
    }

    void RightClick() final {
        OpenContextMenu();
    }
}
