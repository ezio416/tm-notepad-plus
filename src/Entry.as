// c 2025-07-28
// m 2025-07-30

enum EntryType {
    File,
    Folder,
    Unknown
}

class Entry {
    int2      contextMenuLocation;
    bool      contextMenuOpen = false;
    string    newName;
    Folder@   parent;
    string    path;
    bool      renameOpen      = false;
    EntryType type            = EntryType::Unknown;

    bool get_exists() {  // override
        return false;
    }

    string get_icon() {  // override
        return "";
    }

    string get_name() final {
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
                    if (UI::MenuItem(Icons::ExternalLinkSquare + " Open in Editor")) {
                        Open();
                        contextMenuOpen = false;
                    }
                    break;

                case EntryType::Folder:
                    UI::BeginDisabled(this is workingFolder);
                    if (UI::MenuItem(Icons::ExternalLinkSquare + " Open as Workspace")) {
                        Open();
                        contextMenuOpen = false;
                    }
                    UI::EndDisabled();

                    if (UI::MenuItem(Icons::ExternalLink + " Open in Windows Explorer")) {
                        OpenExplorerPath(path);
                        contextMenuOpen = false;
                    }

                    if (UI::MenuItem(Icons::ExternalLink + " Open in Preferred Text Editor ("
                    + tostring(Meta::GetPreferredTextEditor()) + ")")) {
                        Meta::OpenTextEditor(path);
                        contextMenuOpen = false;
                    }

                    break;
            }
            UI::PopFont();

            if (type == EntryType::Folder) {
                UI::Separator();

                if (UI::BeginMenu(Icons::Plus + " New")) {
                    if (UI::MenuItem(Icons::File + " File")) {
                        trace("creating new file in " + path);
                        auto folder = cast<Folder>(this);
                        if (folder.CreateFile()) {
                            folder.Enumerate();
                        }
                        contextMenuOpen = false;
                    }

                    if (UI::MenuItem(Icons::Folder + " Folder")) {
                        trace("creating new folder in " + path);
                        auto folder = cast<Folder>(this);
                        if (folder.CreateFolder()) {
                            folder.Enumerate();
                        }
                        contextMenuOpen = false;
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
                        case EntryType::File:
                            if (true
                                and cast<File>(this).Delete()
                                and parent !is null
                            ) {
                                parent.Enumerate();
                            }
                            break;

                        case EntryType::Folder:
                            if (true
                                and cast<Folder>(this).Delete(true)
                                and parent !is null
                            ) {
                                parent.Enumerate();
                            }
                            break;
                    }

                    contextMenuOpen = false;
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
                    contextMenuOpen = false;
                    if (parent !is null) {
                        parent.Enumerate();
                    }
                }
                UI::EndDisabled();

                UI::EndMenu();
            } else {
                renameOpen = false;
            }

            UI::Separator();

            if (UI::MenuItem(Icons::Info + " Properties")) {
                print("click properties");
                contextMenuOpen = false;
            }
        }
        UI::End();
    }

    void RightClick() final {
        startnew(CoroutineFunc(RightClickAsync));
    }

    void RightClickAsync() final {
        if (activeContextMenu !is null) {
            activeContextMenu.contextMenuOpen = false;
            @activeContextMenu = null;
            yield();
        }

        const vec2 mousePos = UI::GetMousePos();
        contextMenuLocation = int2(int(mousePos.x), int(mousePos.y));

        contextMenuOpen = true;
        @activeContextMenu = this;
    }
}
