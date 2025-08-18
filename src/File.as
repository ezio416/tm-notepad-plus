// c 2025-07-27
// m 2025-08-18

class File : Entry {
    MemoryBuffer@ buffer;
    string        contents;
    bool          dirty    = false;
    bool          load     = false;
    bool          selected = false;
    string        unsavedContents;

    bool get_exists() override {
        return IO::FileExists(path);
    }

    string get_extension() {
        return Path::GetExtension(path);
    }

    string get_icon() override {
        return GetIcon(extension);
    }

    File(const string&in path) {
        super(path);
        type = EntryType::File;
    }

    bool Copy(const string&in path) {
        try {
            IO::Copy(this.path, path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool Create() override {
        if (exists) {
            return true;
        }

        try {
            IO::File file(path, IO::FileMode::Write);
            file.Close();
            trace("created file: " + path);
            return true;
        } catch {
            return false;
        }
    }

    bool Delete() {
        try {
            IO::Delete(path);
            warn("deleted file: " + path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void Edit() {
        for (uint i = 0; i < openFiles.Length; i++) {
            if (openFiles[i].path == path) {
                selected = true;
                return;
            }
        }

        load = true;
        selected = true;
        openFiles.InsertLast(this);
    }

    void InputTextCallback(UI::InputTextCallbackData@ data) {
        ;
    }

    void Open() override {
        Edit();
    }

    bool Read() {
        warn("reading file: " + path);

        try {
            IO::File file(path, IO::FileMode::Read);
            contents = file.ReadToEnd();
            unsavedContents = contents;
            file.Close();
            dirty = false;
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool ReadBuffer() {
        warn("reading file: " + path);

        try {
            IO::File file(path, IO::FileMode::Read);
            @buffer = file.Read(file.Size());
            file.Close();
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    void RenderEditTab() {
        int flags = UI::TabItemFlags::None;
        if (selected) {
            flags |= UI::TabItemFlags::SetSelected;
            selected = false;
        }

        if (dirty) {
            flags |= UI::TabItemFlags::UnsavedDocument;
            const bool open = UI::BeginTabItem((valid ? "" : "\\$F00") + name + "##" + path, flags);
            UI::SetItemTooltip(path + (valid ? "" : "\nReference is invalid, you should close this tab!"));
            if (!open) {
                return;
            }

        } else {
            bool open = true;
            const bool shown = UI::BeginTabItem((valid ? "" : "\\$F00") + name + "##" + path, open, flags);
            UI::SetItemTooltip(path + (valid ? "" : "\nReference is invalid, you should close this tab!"));
            if (!open) {
                if (shown) {
                    UI::EndTabItem();
                }
                const int index = openFiles.FindByRef(this);
                if (index > -1) {
                    openFiles.RemoveAt(index);
                }
                return;
            }
            if (!shown) {
                return;
            }
        }

        if (load) {
            load = false;
            Read();
        }

        if (UI::Button(Icons::Upload + " Load")) {
            Read();
        }

        UI::SameLine();
        UI::BeginDisabled(!dirty);
        if (UI::Button(Icons::FloppyO + " Save")) {
            Write();
        }
        UI::EndDisabled();

        UI::SameLine();
        UI::BeginDisabled(!dirty);
        if (UI::Button(Icons::Undo + " Revert")) {
            Revert();
        }
        UI::EndDisabled();

        bool changed = false;
        UI::PushFont(UI::Font::DefaultMono);
        unsavedContents = UI::InputTextMultiline(
            "##unsaved",
            unsavedContents,
            changed,
            UI::GetContentRegionAvail(),
            UI::InputTextFlags(UI::InputTextFlags::AllowTabInput | UI::InputTextFlags::CallbackAlways),
            UI::InputTextCallback(InputTextCallback)
        );
        UI::PopFont();

        if (changed) {
            dirty = true;
        }

        UI::EndTabItem();
    }

    void Revert() {
        if (dirty) {
            unsavedContents = contents;
            dirty = false;
        }
    }

    bool Write() {
        warn("writing file: " + path);

        try {
            IO::File file(path, IO::FileMode::Write);
            file.Write(unsavedContents);
            file.Close();
            contents = unsavedContents;
            dirty = false;
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool WriteBuffer() {
        warn("writing file: " + path);

        try {
            IO::File file(path, IO::FileMode::Write);
            file.Write(buffer);
            file.Close();
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }
}
