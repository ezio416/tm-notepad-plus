// c 2025-07-28
// m 2025-07-30

dictionary icons;

string GetIcon(const string&in extension) {
    const string lower = extension.ToLower();
    if (icons.Exists(lower)) {
        return string(icons[lower]);
    }

    return Icons::File;
}

void InitDriveLetters() {
    string drive;
    string letter = " ";

    for (uint i = 65; i < 91; i++) {
        letter[0] = i;
        drive = letter + ":";
        if (IO::FolderExists(drive)) {
            validDriveLetters.InsertLast(drive);
        }
    }
}

void InitIcons() {  // vscode extension doesn't do well with large statically initialized dicts
    icons.Set(".as",            Icons::Heartbeat);
    icons.Set(".bmp",           Icons::FileImageO);
    icons.Set(".gitattributes", Icons::CodeFork);
    icons.Set(".gitignore",     Icons::CodeFork);
    icons.Set(".ini",           Icons::Wrench);
    icons.Set(".jpg",           Icons::FileImageO);
    icons.Set(".jpeg",          Icons::FileImageO);
    icons.Set(".json",          Icons::Wrench);
    icons.Set(".md",            Icons::InfoCircle);
    icons.Set(".mp3",           Icons::VolumeUp);
    icons.Set(".mp4",           Icons::FileVideoO);
    icons.Set(".op",            Icons::FileArchiveO);
    icons.Set(".pdf",           Icons::FilePdfO);
    icons.Set(".png",           Icons::FileImageO);
    icons.Set(".py",            Icons::Python);
    icons.Set(".toml",          Icons::Wrench);
    icons.Set(".txt",           Icons::FileTextO);
    icons.Set(".wav",           Icons::VolumeUp);
    icons.Set(".xcf",           Icons::Gimp);
}

void InputCallback(UI::InputTextCallbackData@ data) {
    ;
}

void SetWorkingFolder(const string&in path) {
    SetWorkingFolder(Folder(path));
}

void SetWorkingFolder(Folder@ folder) {
    if (true
        and folder !is null
        and IO::FolderExists(folder.path)
    ) {
        @workingFolder = folder;
        S_WorkspaceFolder = workingFolder.path;
        trace("set working folder to " + folder.path);
    }
}
