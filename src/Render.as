// c 2025-07-27
// m 2025-08-19

void RenderFileTabs() {
    UI::BeginTabBar("##tabs-open", UI::TabBarFlags::Reorderable);

    for (uint i = 0; i < openFiles.Length; i++) {
        openFiles[i].RenderEditTab();
    }

    UI::EndTabBar();
}

void RenderWindow() {
    if (UI::BeginMenuBar()) {
        if (UI::BeginMenu("File")) {
            if (UI::BeginMenu(Icons::Server + " Change drive")) {
                for (uint i = 0; i < validDriveLetters.Length; i++) {
                    if (UI::MenuItem(validDriveLetters[i])) {
                        SetWorkingFolder(validDriveLetters[i]);
                    }
                }

                UI::EndMenu();
            }

            UI::Separator();

            if (UI::BeginMenu(Icons::Star + " Open favorite", Favorite::folders.Length > 0)) {
                if (UI::MenuItem(Icons::TrashO + " Clear favorites")) {
                    Favorite::Clear();
                    Favorite::Save();
                }

                UI::Separator();

                for (uint i = 0; i < Favorite::folders.Length; i++) {
                    UI::BeginDisabled(true
                        and workingFolder !is null
                        and workingFolder.path == Favorite::folders[i]
                    );
                    if (UI::MenuItem(Favorite::folders[i])) {
                        SetWorkingFolder(Favorite::folders[i]);
                    }
                    UI::EndDisabled();
                }

                UI::EndMenu();
            }

            if (UI::BeginMenu(Icons::ClockO + " Open recent", Recent::folders.Length > 0)) {
                if (UI::MenuItem(Icons::TrashO + " Clear recent")) {
                    Recent::Clear();
                    Recent::Save();
                    Recent::Add(workingFolder);
                }

                UI::Separator();

                for (int i = Recent::folders.Length - 1; i >= 0; i--) {
                    UI::BeginDisabled(true
                        and workingFolder !is null
                        and workingFolder.path == Recent::folders[i]
                    );
                    if (UI::MenuItem(Recent::folders[i])) {
                        SetWorkingFolder(Recent::folders[i]);
                    }
                    UI::EndDisabled();
                }

                UI::EndMenu();
            }

            UI::EndMenu();
        }

        if (UI::BeginMenu("View")) {
            if (UI::MenuItem("Editor monospace font", "", S_EditorMonospace)) {
                S_EditorMonospace = !S_EditorMonospace;
            }

            if (UI::BeginMenu("Editor font size")) {
                S_EditorFontSize = Math::Clamp(UI::InputInt("##font-size", S_EditorFontSize), 8, 100);
                UI::EndMenu();
            }

            UI::EndMenu();
        }

        UI::EndMenuBar();
    }

    const vec4 frameBg = UI::GetStyleColor(UI::Col::FrameBg);

    UI::PushStyleColor(UI::Col::FrameBg, vec4(vec3(0.1f), 1.0f));

    if (UI::BeginChild(
        "##child-explorer",
        vec2(0.0f, UI::GetContentRegionAvail().y), UI::ChildFlags::FrameStyle | UI::ChildFlags::ResizeX)
    ) {
        UI::SetNextItemWidth(UI::GetContentRegionAvail().x);
        UI::PushStyleColor(UI::Col::FrameBg, frameBg);
        bool enter = false;
        S_WorkspaceFolder = UI::InputText("##working folder", S_WorkspaceFolder, enter, UI::InputTextFlags::EnterReturnsTrue);
        UI::PopStyleColor();

        if (enter) {
            SetWorkingFolder(S_WorkspaceFolder);
        }

        if (workingFolder !is null) {
            if (workingFolder.pluginFolder) {
                UI::SeparatorText("Plugin Controls");

                Meta::Plugin@ plugin = Meta::GetPluginFromID(workingFolder.pluginId);

                UI::BeginDisabled(plugin !is null);
                if (UI::Button("Load##plugin")) {
                    workingFolder.LoadPlugin();
                }
                UI::EndDisabled();

                UI::BeginDisabled(plugin is null);
                UI::SameLine();
                if (UI::Button("Reload##plugin")) {
                    workingFolder.ReloadPlugin();
                }
                UI::SameLine();
                if (UI::Button("Unload##plugin")) {
                    workingFolder.UnloadPlugin();
                }
                UI::EndDisabled();
            }

            UI::SeparatorText("Explorer");

            if (UI::BeginChild("##child-explorer")) {
                workingFolder.RenderTree();
            }
            UI::EndChild();
        }
    }
    UI::EndChild();

    UI::PopStyleColor();

    UI::SameLine();
    UI::BeginGroup();
    RenderFileTabs();
    UI::EndGroup();
}
