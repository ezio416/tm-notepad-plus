// c 2025-08-19
// m 2025-08-19

namespace Recent {
    const string file = IO::FromStorageFolder("recent.json");
    string[]     folders;

    void Add(const string&in path) {
        trace("adding recent folder: " + path);

        const int index = folders.Find(path);
        if (index > -1) {
            folders.RemoveAt(index);
        }

        folders.InsertLast(path);

        Save();
    }

    void Add(Folder@ folder) {
        if (folder !is null) {
            Add(folder.path);
        }
    }

    void Clear() {
        warn("clearing recent folders");
        folders = {};
    }

    void Load() {
        if (!IO::FileExists(file)) {
            return;
        }

        trace("loading recent folders");

        try {
            Json::Value@ json = Json::FromFile(file);
            Clear();
            for (uint i = 0; i < json.Length; i++) {
                Add(string(json[i]));
            }
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
        }
    }

    void Save() {
        trace("saving recent folders");

        Json::Value@ json = Json::Array();
        for (uint i = 0; i < folders.Length; i++) {
            json.Add(Json::Value(folders[i]));
        }

        try {
            Json::ToFile(file, json, true);
        } catch {
            error(getExceptionInfo());
            PrintActiveContextStack(true);
        }
    }
}
