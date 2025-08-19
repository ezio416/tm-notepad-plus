// c 2025-08-19
// m 2025-08-19

namespace Favorite {
    const string file = IO::FromStorageFolder("favorite.json");
    string[]     folders;

    void Add(const string&in path) {
        trace("adding favorite folder: " + path);

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
        warn("clearing favorite folders");
        folders = {};
    }

    void Load() {
        if (!IO::FileExists(file)) {
            return;
        }

        trace("loading favorite folders");

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

    void Remove(const string&in path) {
        warn("removing favorite: " + path);

        const int index = folders.Find(path);
        if (index > -1) {
            folders.RemoveAt(index);
        }

        Save();
    }

    void Save() {
        trace("saving favorite folders");

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
