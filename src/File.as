// c 2025-07-27
// m 2025-08-19

namespace File {
    enum Type {
        Audio,
        Image,
        Text,
        Unknown
    }
}

class File : Entry {
    Audio::Voice@  audio;
    MemoryBuffer@  buffer;
    string         contents;
    bool           dirty        = false;
    File::Type     fileType     = File::Type::Unknown;
    bool           holdingCtrlS = false;
    bool           load         = false;
    Audio::Sample@ sample;
    bool           selected     = false;
    UI::Texture@   texture;
    string         unsavedContents;

    bool get_exists() override {
        return IO::FileExists(path);
    }

    string get_extension() {
        return Path::GetExtension(path).ToLower();
    }

    string get_icon() override {
        return GetIcon(extension);
    }

    File(const string&in path) {
        super(path);
        type = Entry::Type::File;
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

        if (fileType == File::Type::Unknown) {
            load = true;
        }
        selected = true;
        openFiles.InsertLast(this);
    }

    void InputTextCallback(UI::InputTextCallbackData@ data) {
        if (false
            or UI::IsKeyDown(UI::Key::LeftCtrl)
            or UI::IsKeyDown(UI::Key::RightCtrl)
        ) {
            if (UI::IsKeyDown(UI::Key::S)) {
                if (!holdingCtrlS) {
                    holdingCtrlS = true;
                    if (dirty) {
                        Write();
                    }
                }
            } else {
                holdingCtrlS = false;
            }
        }
    }

    void Open() override {
        Edit();
    }

    bool Read() {
        trace("reading file (text): " + path);

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
        trace("reading file (bytes): " + path);

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
            ReadBuffer();
        }

        if (fileType == File::Type::Unknown) {
            buffer.Seek(0);
            if (buffer.ReadUInt16() == 0x4D42) {  // bmp
                fileType = File::Type::Image;
            }
        }

        if (fileType == File::Type::Unknown) {
            buffer.Seek(0);
            if (buffer.ReadUInt32() & 0xFFFFFF == 0xFFD8FF) {  // jpg
                fileType = File::Type::Image;
            }
        }

        if (fileType == File::Type::Unknown) {
            buffer.Seek(0);
            if (buffer.ReadUInt64() == 0x0A1A0A0D474E5089) {  // png
                fileType = File::Type::Image;
            }
        }

        if (fileType == File::Type::Unknown) {
            buffer.Seek(0);
            uint bytes = buffer.ReadUInt32();
            if (bytes == 0x46464952) {  // riff
                buffer.Seek(8);
                bytes = buffer.ReadUInt32();
                if (bytes == 0x45564157) {  // wav
                    fileType = File::Type::Audio;
                } else if (bytes == 0x50424557) {  // webp, unsupported
                    fileType = File::Type::Image;
                }

            } else if (false
                or bytes & 0xFFFFFF == 0x334449
                or bytes & 0xFFFF == 0xF2FF
                or bytes & 0xFFFF == 0xF3FF
                or bytes & 0xFFFF == 0xFBFF
            ) {  // mp3
                fileType = File::Type::Audio;
            }
        }

        if (true
            and fileType == File::Type::Image
            and texture is null
        ) {
            @texture = UI::LoadTexture(buffer);
        }

        if (texture !is null) {
            fileType = File::Type::Image;

            const vec2 size = texture.GetSize();
            UI::Text("image size: " + tostring(size));

            if (UI::BeginChild("##child-image")) {
                UI::Image(texture, vec2(UI::GetContentRegionAvail().x) * vec2(1.0f, size.y / Math::Max(size.x, 1.0f)));
            }
            UI::EndChild();

            UI::EndTabItem();
            return;
        }

        if (true
            and fileType == File::Type::Audio
            and audio is null
        ) {
            @sample = Audio::LoadSample(buffer);
            try {
                @audio = Audio::Play(sample, 0.5f);
                audio.Pause();
            } catch { }
        }

        if (audio !is null) {
            fileType = File::Type::Audio;

            if (audio.IsPaused()) {
                if (UI::Button(Icons::Play)) {
                    audio.Play();
                }
            } else if (UI::Button(Icons::Pause)) {
                audio.Pause();
            }

            UI::SameLine();
            const uint position = uint(audio.GetPosition() * 1000.0);
            const uint length = uint(audio.GetLength() * 1000.0);
            UI::SetNextItemWidth(UI::GetContentRegionAvail().x);
            UI::SliderInt(
                "##audio-slider",
                position,
                0,
                length,
                Time::Format(position) + " / " + Time::Format(length),
                UI::SliderFlags::NoInput
            );

            if (true
                and position == length
                and sample !is null
            ) {
                @audio = Audio::Play(sample, 0.5f);
                audio.Pause();
            }

            UI::EndTabItem();
            return;
        }

        fileType = File::Type::Text;

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

        UI::Text("Note: this text input box does not properly render format codes, i.e. \\$4FC\\\\\\$$$4FC");

        bool changed = false;
        UI::PushFont(UI::Font::DefaultMono, S_EditorFontSize);
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
