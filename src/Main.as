const string  pluginColor = "\\$F0A";
const string  pluginIcon  = Icons::Pencil;
Meta::Plugin@ pluginMeta  = Meta::ExecutingPlugin();
const string  pluginTitle = pluginColor + pluginIcon + "\\$G " + pluginMeta.Name;

Entry@   activeProperties;
File@[]  openFiles;
string[] validDriveLetters;
Folder@  workingFolder;

void Main() {
    InitIcons();
    InitDriveLetters();
    Favorite::Load();
    Recent::Load();

    if (S_WorkspaceFolder.Length > 0) {
        SetWorkingFolder(S_WorkspaceFolder);
    }

    if (!S_InitDefaultFavorites) {
        Favorite::InitDefault();
    }
}

void OnSettingsChanged() {
    S_EditorFontSize = Math::Clamp(S_EditorFontSize, 8, 100);
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

    UI::SetNextWindowSize(500, 500, UI::Cond::FirstUseEver);

    if (UI::Begin(
        pluginTitle + "###main-" + pluginMeta.ID,
        S_Enabled,
        UI::GetDefaultWindowFlags() | UI::WindowFlags::MenuBar
    )) {
        RenderWindow();
    }
    UI::End();

    if (activeProperties !is null) {
        activeProperties.RenderProperties();
    }
}

void RenderMenu() {
    if (UI::MenuItem(pluginTitle, "", S_Enabled)) {
        S_Enabled = !S_Enabled;
    }
}
