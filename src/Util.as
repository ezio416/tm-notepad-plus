dictionary icons;

const uint64 KiB = 1024;
const uint64 MiB = 1048576;
const uint64 GiB = 1073741824;

string FormatBytes(uint64 bytes) {
    if (bytes < KiB) {
        return Text::Format("%d bytes", bytes);
    }

    if (bytes < MiB) {
        return Text::Format("%.2f KiB", double(bytes) / KiB);
    }

    if (bytes < GiB) {
        return Text::Format("%.2f MiB", double(bytes) / MiB);
    }

    return Text::Format("%.2f GiB", double(bytes) / GiB);
}

string GetIcon(const string&in extension) {
    if (icons.Exists(extension)) {
        return string(icons[extension]);
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
    icons.Set(".c",             Icons::C);
    icons.Set(".cpp",           Icons::Code);
    icons.Set(".cs",            Icons::Code);
    icons.Set(".css",           Icons::Code);
    icons.Set(".gitattributes", Icons::CodeFork);
    icons.Set(".gitignore",     Icons::CodeFork);
    icons.Set(".h",             Icons::C);
    icons.Set(".htm",           Icons::Code);
    icons.Set(".html",          Icons::Code);
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
    icons.Set(".webp",          Icons::FileImageO);
    icons.Set(".xcf",           Icons::Gimp);
    icons.Set(".xml",           Icons::Code);
}

void SetWorkingFolder(const string&in path) {
    SetWorkingFolder(Folder(path));
}

void SetWorkingFolder(Folder@ folder) {
    if (true
        and folder !is null
        and folder.exists
    ) {
        @workingFolder = folder;
        S_WorkspaceFolder = folder.path;
        workingFolder.Enumerate();
        trace("set working folder to " + folder.path);
        Recent::Add(folder);
    }
}
