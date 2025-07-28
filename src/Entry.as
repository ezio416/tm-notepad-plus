// c 2025-07-28
// m 2025-07-28

enum EntryType {
    File,
    Folder,
    Unknown
}

class Entry {
    Folder@   parent;
    string    path;
    EntryType type = EntryType::Unknown;

    bool get_exists() {
        return false;  // override
    }

    string get_name() {
        return Path::GetFileName(path);
    }

    Entry(const string&in path) {
        this.path = path.Replace("\\", "/");
    }

    bool Move(const string&in path) {
        try {
            IO::Move(this.path, path);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }

    bool Rename(const string&in name) {
        try {
            IO::Move(path, Path::GetDirectoryName(path) + name);
            return true;
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
            return false;
        }
    }
}
