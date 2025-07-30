// c 2025-07-27
// m 2025-07-30

const string  pluginColor = "\\$F0A";
const string  pluginIcon  = Icons::Pencil;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

Entry@   activeContextMenu;
vec2     lastWindowPos;
vec2     lastWindowSize;
File@[]  openFiles;
string[] validDriveLetters;
Folder@  workingFolder;

void Main() {
    InitIcons();

    InitDriveLetters();

    if (S_WorkspaceFolder.Length > 0) {
        SetWorkingFolder(S_WorkspaceFolder);
    }

    while (true) {
        yield();

        if (true
            and activeContextMenu !is null
            and !activeContextMenu.contextMenuOpen
        ) {
            @activeContextMenu = null;
        }
    }
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (true
        and down
        and key == VirtualKey::Escape
        and activeContextMenu !is null
    ) {
        activeContextMenu.contextMenuOpen = false;
        return UI::InputBlocking::Block;
    }

    return UI::InputBlocking::DoNothing;
}

UI::InputBlocking OnMouseButton(bool down, int, int, int) {
    if (true
        and down
        and activeContextMenu !is null
    ) {
        activeContextMenu.contextMenuOpen = false;
        return UI::InputBlocking::Block;
    }

    return UI::InputBlocking::DoNothing;
}

void Render() {
    if (false
        or !S_Enabled
        or (true
            and S_HideWithGame
            and !UI::IsGameUIVisible()
        )
        or (true
            and S_HideWithOP
            and !UI::IsOverlayShown()
        )
    ) {
        return;
    }

    if (UI::Begin(pluginTitle + "###main-" + pluginMeta.ID, S_Enabled, UI::WindowFlags::MenuBar)) {
        const vec2 pos = UI::GetWindowPos();
        if (true
            and activeContextMenu !is null
            and activeContextMenu.contextMenuOpen
            and pos != lastWindowPos
        ) {
            activeContextMenu.contextMenuOpen = false;
            @activeContextMenu = null;
        }
        lastWindowPos = pos;

        const vec2 size = UI::GetWindowSize();
        if (true
            and activeContextMenu !is null
            and activeContextMenu.contextMenuOpen
            and size != lastWindowSize
        ) {
            activeContextMenu.contextMenuOpen = false;
            @activeContextMenu = null;
        }
        lastWindowSize = size;

        RenderWindow();

        if (activeContextMenu !is null) {
            activeContextMenu.RenderContextMenu();
        }

    } else {
        if (true
            and activeContextMenu !is null
            and activeContextMenu.contextMenuOpen
        ) {
            activeContextMenu.contextMenuOpen = false;
            @activeContextMenu = null;
        }
    }
    UI::End();

    // if (activeContextMenu !is null) {
    //     UI::Text("active context menu: " + activeContextMenu.name);
    // } else {
    //     UI::Text("no active context menu");
    // }
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}
