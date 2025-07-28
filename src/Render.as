// c 2025-07-27
// m 2025-07-28

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
        workingFolderPath = UI::InputText("##working folder", workingFolderPath);
        UI::PopStyleColor();

        if (UI::Button("Load")) {
            @workingFolder = Folder(workingFolderPath);
        }

        if (workingFolder !is null) {
            if (UI::Button("Enumerate")) {
                workingFolder.Enumerate(true);
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
