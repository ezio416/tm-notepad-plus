// c 2025-07-27
// m 2025-07-30

void RenderFileTabs() {
    UI::BeginTabBar("##tabs-open", UI::TabBarFlags::Reorderable);

    for (uint i = 0; i < openFiles.Length; i++) {
        openFiles[i].RenderEditTab();
    }

    UI::EndTabBar();
}

void RenderWindow() {
    const vec4 frameBg = UI::GetStyleColor(UI::Col::FrameBg);

    UI::PushStyleColor(UI::Col::FrameBg, vec4(vec3(0.1f), 1.0f));

    if (UI::BeginChild(
        "##child-explorer",
        vec2(0.0f, UI::GetContentRegionAvail().y), UI::ChildFlags::FrameStyle | UI::ChildFlags::ResizeX)
    ) {
        UI::SetNextItemWidth(UI::GetContentRegionAvail().x);
        UI::PushStyleColor(UI::Col::FrameBg, frameBg);
        S_WorkspaceFolder = UI::InputText("##working folder", S_WorkspaceFolder);
        UI::PopStyleColor();

        UI::BeginDisabled(false
            or (true
                and workingFolder !is null
                and workingFolder.path == S_WorkspaceFolder
            )
            or S_WorkspaceFolder.Length == 0
        );
        if (UI::Button("Load")) {
            SetWorkingFolder(Folder(S_WorkspaceFolder));
            workingFolder.Enumerate(true);
        }
        UI::EndDisabled();

        if (workingFolder !is null) {
            if (workingFolder.pluginFolder) {
                Meta::Plugin@ plugin = Meta::GetPluginFromID(workingFolder.pluginId);

                UI::AlignTextToFramePadding();
                UI::Text("Plugin Controls:");

                UI::BeginDisabled(plugin !is null);
                UI::SameLine();
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

            workingFolder.RenderTreeSimple();
        }
    }
    UI::EndChild();

    UI::PopStyleColor();

    UI::SameLine();
    UI::BeginGroup();
    RenderFileTabs();
    UI::EndGroup();
}
